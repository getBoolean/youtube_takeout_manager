import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/oauth_configured.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_notices.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/account_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_channels_section.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_account_header.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import 'package:youtube_takeout_manager/src/features/device_cache/presentation/cache_section.dart';
import 'package:youtube_takeout_manager/src/features/quota/presentation/quota_section.dart';
import '../application/saved_takeouts.dart';
import '../application/takeout_notifier.dart';
import '../application/takeout_remover.dart';
import '../application/takeout_selection_notifier.dart';
import '../application/viewed_takeout_providers.dart';
import '../domain/takeout_channel.dart';
import 'import_takeout.dart';
import 'leave_channel_screens.dart';
import 'other_accounts_section.dart';
import 'skipped_rows_banner.dart';

Future<void> showTakeoutsDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const TakeoutsDialog());

/// The Google account the viewed takeout is from, with its channels to view
/// and sign in, importing a takeout, and the other saved accounts to switch
/// to, then the app's YouTube API quota and on-device cache. Errors show in
/// place, never in another popup.
class TakeoutsDialog extends StatelessWidget {
  const TakeoutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final tiny = isTinyWidth(context);
    return Dialog(
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(tiny ? 4 : 16, 8, tiny ? 4 : 8, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: tiny ? 4 : 8),
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Takeouts',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                  ),
                  const CloseButton(),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsetsDirectional.only(end: tiny ? 0 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AccountTile(),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          QuotaSection(),
                          SizedBox(height: 24),
                          CacheSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The viewed takeout's Google account in an outlined tile: its channels on
/// a panel inside it, importing a takeout, and, expanded, the other saved
/// accounts.
class _AccountTile extends ConsumerStatefulWidget {
  const _AccountTile();

  @override
  ConsumerState<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends ConsumerState<_AccountTile> {
  /// Whether the other accounts show.
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channels = ref.watch(takeoutChannelsProvider);
    final profiles = ref.watch(savedSignInsProvider).value ?? const {};
    final data = ref.watch(
      takeoutProvider.select(
        (t) => (
          exportedAt: t.value?.data.latestExportAt,
          skippedComments: t.value?.data.skippedCommentRows ?? 0,
          skippedLiveChats: t.value?.data.skippedLiveChatRows ?? 0,
        ),
      ),
    );
    final deletionRunning =
        ref.watch(deletionProcessingProvider) != DeletionProcessingState.idle;
    // Nothing else to show without a takeout or a sign-in.
    final expandable =
        channels.isNotEmpty ||
        profiles.isNotEmpty ||
        (ref.watch(savedTakeoutsProvider).value?.isNotEmpty ?? false);
    final expanded = _expanded && expandable;

    return Card.outlined(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTinyWidth(context) ? 4 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (deletionRunning) ...[
              const _DeletionRunningBanner(),
              const SizedBox(height: 12),
            ],
            GoogleAccountHeader(
              profile: accountProfileFor(channels, profiles),
              mainChannel: channels.firstOrNull,
              exportedAt: channels.isEmpty ? null : data.exportedAt,
              expanded: expanded,
              onToggle: expandable
                  ? () => setState(() => _expanded = !expanded)
                  : null,
            ),
            if (data.skippedComments > 0 || data.skippedLiveChats > 0) ...[
              const SizedBox(height: 12),
              SkippedRowsBanner(
                comments: data.skippedComments,
                liveChats: data.skippedLiveChats,
              ),
            ],
            if (channels.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Channels(
                channels: channels,
                profiles: profiles,
                deletionRunning: deletionRunning,
              ),
              if (!ref.watch(oauthConfiguredProvider))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Sign-in isn't configured",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            ImportTakeout(onImported: () => setState(() => _expanded = false)),
            if (expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _OtherAccounts(
                deletionRunning: deletionRunning,
                onSwitched: () => setState(() => _expanded = false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The viewed account's channels, with why any didn't end up signed in.
class _Channels extends ConsumerWidget {
  final List<TakeoutChannel> channels;
  final Map<String, SignInProfile> profiles;
  final bool deletionRunning;

  const _Channels({
    required this.channels,
    required this.profiles,
    required this.deletionRunning,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedTakeoutsProvider).value ?? const [];
    final notices = ref.read(signInNoticesProvider.notifier);
    final selection = ref.read(takeoutSelectionProvider.notifier);

    return AccountChannelsSection(
      channels: channels,
      viewedChannelId: ref.watch(viewedChannelIdProvider),
      signedInChannelIds: profiles.keys.toSet(),
      signInEnabled: ref.watch(oauthConfiguredProvider),
      deletionRunning: deletionRunning,
      notices: ref.watch(signInNoticesProvider),
      savedChannelIds: {for (final t in saved) ...t.channelIds},
      // This dialog stays open unless it was over a screen tied to the
      // channel shown before.
      onView: (id) =>
          leaveChannelScreensAfter(context, () => selection.selectChannel(id)),
      onSignIn: notices.signIn,
      onSignOut: (id) =>
          ref.read(signInServiceProvider.notifier).signOut(channelId: id),
      onDismissNotice: notices.dismiss,
      onViewChosen: (id) {
        // The channel chosen instead when signing in, in its takeout.
        final takeout = ref.read(savedTakeoutWithChannelProvider(id));
        if (takeout == null) return;
        leaveChannelScreensAfter(
          context,
          () => selection.select(takeout.id, channelId: id),
        );
      },
    );
  }
}

/// Every other saved account to switch to or remove, and sign-ins no
/// takeout has.
class _OtherAccounts extends ConsumerWidget {
  final bool deletionRunning;

  /// Called once another account is shown instead.
  final VoidCallback onSwitched;

  const _OtherAccounts({
    required this.deletionRunning,
    required this.onSwitched,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedTakeoutsProvider).value ?? const [];
    final viewingId = ref.watch(
      takeoutSelectionProvider.select((s) => s.value?.takeoutId),
    );
    final profiles = ref.watch(savedSignInsProvider).value ?? const {};
    final inTakeouts = {for (final t in saved) ...t.channelIds};
    final viewed = saved.where((t) => t.id == viewingId).firstOrNull;
    final remover = ref.read(takeoutRemoverProvider.notifier);

    return OtherAccountsSection(
      viewedAccount: viewed,
      accounts: [
        for (final summary in saved)
          if (summary.id != viewingId)
            OtherAccount(
              summary: summary,
              profile: accountProfileFor(summary.channels, profiles),
            ),
      ],
      deletionRunning: deletionRunning,
      onView: (takeoutId, channelId) async {
        final shown = await leaveChannelScreensAfter(
          context,
          () => ref
              .read(takeoutSelectionProvider.notifier)
              .select(takeoutId, channelId: channelId),
        );
        if (shown) onSwitched();
      },
      planRemoval: remover.planRemoval,
      onRemove: (removal) => removal.summary.id == viewingId
          ? leaveChannelScreensAfter(
              context,
              () => remover.removeTakeout(removal),
            )
          : remover.removeTakeout(removal),
      otherSignIns: [
        for (final profile in profiles.values)
          if (!inTakeouts.contains(profile.channelId)) profile,
      ],
      onRemoveSignIn: (id) =>
          ref.read(savedSignInsProvider.notifier).remove(id, revoke: true),
    );
  }
}

/// The YouTube API is deleting, so switching, signing out and removing the
/// viewed account wait until it stops.
class _DeletionRunningBanner extends ConsumerWidget {
  const _DeletionRunningBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pausing =
        ref.watch(deletionProcessingProvider) ==
        DeletionProcessingState.pausing;
    return NoticeBanner(
      key: const ValueKey('deletion-running'),
      title: 'Deleting through the YouTube API',
      error: false,
      actions: [
        TextButton(
          onPressed: pausing
              ? null
              : () => ref
                    .read(deletionProcessingProvider.notifier)
                    .pauseProcessing(),
          child: Text(
            pausing ? 'Pausing…' : 'Pause deletion',
            textAlign: TextAlign.center,
          ),
        ),
      ],
      children: const [
        Text(
          'Switching accounts or channels, signing out, importing a takeout '
          'and removing the one shown wait until it stops.',
        ),
      ],
    );
  }
}
