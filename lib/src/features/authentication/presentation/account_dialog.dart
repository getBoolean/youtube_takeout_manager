import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/channel_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/presentation/quota_status_bar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_remover.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/leave_channel_screens.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/other_accounts_section.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/skipped_rows_banner.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_title_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import '../application/saved_sign_ins.dart';
import '../application/sign_in_notices.dart';
import '../application/sign_in_service.dart';
import '../domain/account_profile.dart';
import '../domain/sign_in_notice.dart';
import '../domain/sign_in_profile.dart';
import 'account_channels_section.dart';
import 'google_account_header.dart';

Future<void> showAccountDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const AccountDialog());

/// The Google account the viewed takeout is from, with its channels to view
/// and sign in, importing a takeout, and the other saved accounts to switch
/// to, then the app's
/// YouTube API quota and on-device cache. Errors show in place, never in
/// another popup.
class AccountDialog extends ConsumerWidget {
  /// Whether Google sign-in has a client configured. Overridable in tests.
  final bool oauthConfigured;

  const AccountDialog({
    super.key,
    @visibleForTesting this.oauthConfigured = isOAuthConfigured,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    _AccountTile(oauthConfigured: oauthConfigured),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QuotaSection(),
                          SizedBox(height: 24),
                          _CacheSection(),
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
  final bool oauthConfigured;

  const _AccountTile({required this.oauthConfigured});

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
                oauthConfigured: widget.oauthConfigured,
                deletionRunning: deletionRunning,
              ),
              if (!widget.oauthConfigured)
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
  final bool oauthConfigured;
  final bool deletionRunning;

  const _Channels({
    required this.channels,
    required this.profiles,
    required this.oauthConfigured,
    required this.deletionRunning,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lost = ref.watch(lostSignInProvider)?.profile.channelId;
    final notices = {
      if (lost != null && !profiles.containsKey(lost))
        lost: const SignInStoppedWorking(),
      ...ref.watch(signInNoticesProvider),
    };
    final saved = ref.watch(savedTakeoutsProvider).value ?? const [];

    return AccountChannelsSection(
      channels: channels,
      viewedChannelId: ref.watch(viewedChannelIdProvider),
      signedInChannelIds: profiles.keys.toSet(),
      signInEnabled: oauthConfigured,
      deletionRunning: deletionRunning,
      notices: notices,
      savedChannelIds: {for (final t in saved) ...t.channelIds},
      onView: (id) => _view(context, ref, id),
      onSignIn: ref.read(signInNoticesProvider.notifier).signIn,
      onSignOut: (id) =>
          ref.read(signInServiceProvider.notifier).signOut(channelId: id),
      onDismissNotice: (id) => switch (notices[id]) {
        SignInStoppedWorking() =>
          ref.read(lostSignInProvider.notifier).dismiss(),
        _ => ref.read(signInNoticesProvider.notifier).dismiss(id),
      },
      onViewChosen: (id) => _viewChosen(context, ref, saved, id),
    );
  }

  /// Views [channelId], leaving screens tied to the previous one. This
  /// dialog stays open unless it was over one of those screens.
  Future<void> _view(BuildContext context, WidgetRef ref, String id) async {
    final router = StackRouterScope.of(context)?.controller;
    await ref.read(takeoutSelectionProvider.notifier).selectChannel(id);
    if (context.mounted) {
      leaveChannelScreens(router);
    }
  }

  /// Views the channel chosen instead when signing in, in its takeout.
  Future<void> _viewChosen(
    BuildContext context,
    WidgetRef ref,
    List<TakeoutSummary> saved,
    String channelId,
  ) async {
    final takeout = saved
        .where((t) => t.channelIds.contains(channelId))
        .firstOrNull;
    if (takeout == null) return;
    final router = StackRouterScope.of(context)?.controller;
    await ref
        .read(takeoutSelectionProvider.notifier)
        .select(takeout.id, channelId: channelId);
    if (context.mounted) {
      leaveChannelScreens(router);
    }
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
      onView: (takeoutId, channelId) =>
          _show(context, ref, takeoutId, channelId: channelId),
      planRemoval: remover.planRemoval,
      onRemove: (removal) async {
        final router = StackRouterScope.of(context)?.controller;
        await remover.removeTakeout(removal);
        if (removal.summary.id == viewingId && context.mounted) {
          leaveChannelScreens(router);
        }
      },
      otherSignIns: [
        for (final profile in profiles.values)
          if (!inTakeouts.contains(profile.channelId)) profile,
      ],
      onRemoveSignIn: (id) =>
          ref.read(savedSignInsProvider.notifier).remove(id, revoke: true),
    );
  }

  /// Shows [takeoutId]'s takeout, at [channelId] or the channel last viewed
  /// in it, leaving screens tied to the previous one.
  Future<void> _show(
    BuildContext context,
    WidgetRef ref,
    String takeoutId, {
    String? channelId,
  }) async {
    final router = StackRouterScope.of(context)?.controller;
    await ref
        .read(takeoutSelectionProvider.notifier)
        .select(takeoutId, channelId: channelId);
    if (!context.mounted) return;
    leaveChannelScreens(router);
    onSwitched();
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

class _QuotaSection extends ConsumerWidget {
  const _QuotaSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Section(
      title: 'YouTube API quota',
      description:
          "Your daily YouTube API allowance. It's used to load video titles, "
          'look up your channel, and delete via the API. Deleting via My '
          "Activity doesn't use it.",
      body: const QuotaStatusBar(padding: EdgeInsets.zero),
      action: TextButton.icon(
        onPressed: () => _resetQuota(context, ref),
        icon: isTinyWidth(context) ? null : const Icon(Icons.restart_alt),
        label: const Text('Reset usage', textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _resetQuota(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Quota Usage'),
        content: const Text(
          'This will reset the tracked API quota usage to zero. '
          'Use this if the count is out of sync with your actual usage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(quotaProvider.notifier).resetUsage();

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Quota usage reset.')));
    }
  }
}

class _CacheSection extends ConsumerWidget {
  const _CacheSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Section(
      title: 'Cache',
      description:
          'Video titles and channel thumbnails loaded from YouTube are kept '
          'on this device.',
      action: TextButton.icon(
        onPressed: () => _clearCache(context, ref),
        icon: isTinyWidth(context)
            ? null
            : const Icon(Icons.cleaning_services_outlined),
        label: const Text('Clear cache', textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached video metadata, channel thumbnails, '
          'and not-found IDs. Data will be re-fetched from the YouTube API '
          'on next use.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(videoCacheRepositoryProvider).clearCache();
    await ref.read(channelCacheRepositoryProvider).clearThumbnails();

    ref.invalidate(videoMetadataProvider);
    ref.invalidate(channelThumbnailsProvider);
    // Fetches what was cleared again.
    ref.invalidate(videoTitleFetcherProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Cache cleared.')));
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String description;
  final Widget? body;
  final Widget action;

  const _Section({
    required this.title,
    required this.description,
    this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (body case final body?) ...[const SizedBox(height: 12), body],
        const SizedBox(height: 4),
        action,
      ],
    );
  }
}
