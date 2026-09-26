import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/channel_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/presentation/quota_status_bar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeout_account_section.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeout_switcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import '../application/auth_notifier.dart';
import '../domain/auth_state.dart';
import 'account_avatar.dart';
import 'sign_in_flow.dart';

Future<void> showAccountDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const AccountDialog());

/// The signed-in account, the YouTube API quota it has used today, and the
/// on-device cache.
class AccountDialog extends ConsumerWidget {
  /// Whether Google sign-in has a client configured. Overridable in tests.
  final bool oauthConfigured;

  const AccountDialog({
    super.key,
    @visibleForTesting this.oauthConfigured = isOAuthConfigured,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

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
                    const TakeoutAccountSection(),
                    const SizedBox(height: 24),
                    _AccountHeader(
                      auth: auth,
                      oauthConfigured: oauthConfigured,
                    ),
                    const SizedBox(height: 24),
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

/// The viewed channel's sign-in: the Google account and channel when signed
/// in, otherwise which channel to choose when signing in.
class _AccountHeader extends ConsumerWidget {
  final AuthState? auth;
  final bool oauthConfigured;

  const _AccountHeader({required this.auth, required this.oauthConfigured});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = this.auth;
    final viewed = ref.watch(viewedChannelProvider);
    final channelName =
        viewed?.title ?? auth?.channelTitle ?? viewed?.channelId;
    final name = auth == null
        ? 'Not signed in'
        : auth.displayName ?? auth.email ?? 'Signed in';
    final email = auth?.displayName != null ? auth?.email : null;
    // A narrow window gets a smaller avatar, and the tiniest none, so the
    // name has room.
    final windowWidth = MediaQuery.sizeOf(context).width;
    final tiny = isTinyWidth(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!tiny) ...[
              AccountAvatar(auth: auth, radius: windowWidth < 320 ? 20 : 32),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  if (email != null) Text(email, style: secondary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (auth != null) ...[
          Text(
            'Signed in as ${channelName ?? auth.channelId}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              // Signing out mid-deletion would close the session under it.
              if (!await ensureNotDeleting(context, ref)) return;
              await ref.read(authProvider.notifier).signOut();
            },
            icon: tiny ? null : const Icon(Icons.logout),
            label: const Text('Sign out', textAlign: TextAlign.center),
          ),
        ] else ...[
          if (channelName != null) ...[
            Text(
              "$channelName isn't signed in",
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to load video titles and delete through the YouTube '
              'API. When Google asks, choose $channelName.',
              style: theme.textTheme.bodyMedium,
            ),
          ] else
            Text(
              'Import a takeout to sign in.',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: oauthConfigured && viewed != null
                ? () => signInToViewedChannel(context, ref)
                : null,
            icon: tiny ? null : const Icon(Icons.login),
            label: const Text(
              'Sign in with Google',
              textAlign: TextAlign.center,
            ),
          ),
          if (!oauthConfigured) ...[
            const SizedBox(height: 4),
            Text(
              "Sign-in isn't configured",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
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
