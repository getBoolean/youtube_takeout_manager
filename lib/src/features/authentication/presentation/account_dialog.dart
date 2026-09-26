import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/channel_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/presentation/quota_status_bar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/switch_takeout_dialog.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeout_switcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import '../application/auth_notifier.dart';
import '../application/saved_sign_ins.dart';
import '../domain/account_profile.dart';
import 'account_channels_section.dart';
import 'google_account_header.dart';
import 'sign_in_flow.dart';

Future<void> showAccountDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const AccountDialog());

/// The Google account the viewed takeout is from, with its channels to view
/// and sign in, then the app's YouTube API quota and on-device cache.
class AccountDialog extends ConsumerWidget {
  /// Whether Google sign-in has a client configured. Overridable in tests.
  final bool oauthConfigured;

  const AccountDialog({
    super.key,
    @visibleForTesting this.oauthConfigured = isOAuthConfigured,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 8, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CloseButton(),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AccountSection(oauthConfigured: oauthConfigured),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const _QuotaSection(),
                    const SizedBox(height: 24),
                    const _CacheSection(),
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

/// The viewed takeout's Google account and its channels.
class _AccountSection extends ConsumerWidget {
  final bool oauthConfigured;

  const _AccountSection({required this.oauthConfigured});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final channels = ref.watch(takeoutChannelsProvider);
    final profiles = ref.watch(savedSignInsProvider).value ?? const {};
    final exportedAt = ref.watch(
      takeoutProvider.select((t) => t.value?.data.latestExportAt),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoogleAccountHeader(
          profile: accountProfileFor(channels, profiles),
          mainChannel: channels.firstOrNull,
          exportedAt: channels.isEmpty ? null : exportedAt,
        ),
        if (channels.isNotEmpty) ...[
          const SizedBox(height: 16),
          AccountChannelsSection(
            channels: channels,
            viewedChannelId: ref.watch(viewedChannelIdProvider),
            signedInChannelIds: profiles.keys.toSet(),
            signInEnabled: oauthConfigured,
            onView: (id) => _view(context, ref, id),
            onSignIn: (id) => signInToChannel(context, ref, channelId: id),
            onSignOut: (id) => _signOut(context, ref, id),
          ),
          if (!oauthConfigured)
            Text(
              "Sign-in isn't configured",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: () => showSwitchTakeoutDialog(context),
            icon: isTinyWidth(context) ? null : const Icon(Icons.swap_horiz),
            label: const Text(
              'Switch Google account',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// Views [channelId], leaving screens tied to the previous one. This
  /// dialog stays open unless it was over one of those screens.
  Future<void> _view(BuildContext context, WidgetRef ref, String id) async {
    if (id == ref.read(viewedChannelIdProvider)) return;
    if (!await ensureNotDeleting(context, ref)) return;
    if (!context.mounted) return;
    final router = StackRouterScope.of(context)?.controller;
    await ref.read(takeoutSelectionProvider.notifier).selectChannel(id);
    if (context.mounted) {
      leaveChannelScreens(context, router, closeDialogs: false);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref, String id) async {
    // Signing out mid-deletion would close the session under it.
    if (!await ensureNotDeleting(context, ref)) return;
    await ref.read(authProvider.notifier).signOut(channelId: id);
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
