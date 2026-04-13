import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/oauth_config.dart';
import '../models/deletion_item_status.dart';
import '../models/takeout_data.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/channel_providers.dart';
import '../providers/deletion_queue_provider.dart';
import '../providers/live_chat_providers.dart';
import '../providers/takeout_providers.dart';
import '../providers/video_providers.dart';
import '../router/app_router.dart';
import '../widgets/import_progress_indicator.dart';

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _importing = false;

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final imported = await ref.read(takeoutProvider.notifier).importFiles();
      if (!mounted) return;
      if (imported) {
        final takeout = ref.read(takeoutProvider).value;
        if (takeout != null &&
            takeout.comments.isEmpty &&
            takeout.liveChats.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
              const SnackBar(
                content: Text(
                    'No comments or live chats found in the selected file(s).'),
              ),
            );
          }
        } else {
          if (ref.read(authProvider) == null) {
            if (mounted) {
              ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                const SnackBar(
                  content: Text('Sign in to fetch video metadata and view channels.'),
                ),
              );
            }
            return;
          }
          await ref.read(channelThumbnailsProvider.notifier).loadCache();
          if (mounted) context.router.push(const ChannelListRoute());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final takeoutAsync = ref.watch(takeoutProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Takeout Manager'),
        actions: [
          _buildQueueButton(),
          _buildAuthButton(),
        ],
      ),
      body: Center(
        child: _importing
            ? const ImportProgressIndicator()
            : takeoutAsync.when(
                loading: () => const ImportProgressIndicator(),
                error: (e, _) => _buildError(theme, e),
                data: (takeout) => takeout == null
                    ? _buildImportPrompt(theme)
                    : _buildSummary(context, theme, takeout),
              ),
      ),
    );
  }

  Widget _buildQueueButton() {
    final queueAsync = ref.watch(deletionQueueProvider);
    final pendingCount = queueAsync.value
            ?.where((i) =>
                i.status == DeletionItemStatus.pending ||
                i.status == DeletionItemStatus.inProgress)
            .length ??
        0;

    return Badge(
      isLabelVisible: pendingCount > 0,
      label: Text('$pendingCount'),
      child: IconButton(
        icon: const Icon(Icons.delete_sweep_outlined),
        tooltip: 'Deletion Queue',
        onPressed: () => context.router.push(const DeletionQueueRoute()),
      ),
    );
  }

  Widget _buildAuthButton() {
    final authState = ref.watch(authProvider);
    if (authState != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (authState.photoUrl != null)
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(authState.photoUrl!),
            )
          else
            const Icon(Icons.account_circle),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'sign_out') {
                ref.read(authProvider.notifier).signOut();
              } else if (value == 'clear_cache') {
                _clearCache();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sign_out',
                child: Text('Sign out${authState.email != null ? ' (${authState.email})' : ''}'),
              ),
              const PopupMenuItem(
                value: 'clear_cache',
                child: Text('Clear cache'),
              ),
            ],
          ),
        ],
      );
    }
    return TextButton.icon(
      onPressed: isOAuthConfigured
          ? () => ref.read(authProvider.notifier).signIn()
          : null,
      icon: const Icon(Icons.login),
      label: Text(isOAuthConfigured ? 'Sign In' : 'Sign In (not configured)'),
    );
  }

  Widget _buildImportPrompt(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.upload_file,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Import your Google Takeout data',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Select one or more takeout zip files',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _import,
          icon: const Icon(Icons.folder_open),
          label: const Text('Select Zip Files'),
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme, Object error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text('Failed to load saved data', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('$error', style: theme.textTheme.bodySmall),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _import,
          icon: const Icon(Icons.folder_open),
          label: const Text('Import New Data'),
        ),
      ],
    );
  }

  Future<void> _clearCache() async {
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
    if (confirmed != true || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ref.invalidate(videoMetadataProvider);
    ref.invalidate(channelThumbnailsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Cache cleared.')),
        );
    }
  }

  Future<void> _viewChannels() async {
    if (ref.read(authProvider) == null) {
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
        const SnackBar(
          content: Text('Sign in to fetch video metadata and view channels.'),
        ),
      );
      return;
    }
    await ref.read(channelThumbnailsProvider.notifier).loadCache();
    if (mounted) context.router.push(const ChannelListRoute());
  }

  Widget _buildSummary(BuildContext context, ThemeData theme, TakeoutData takeout) {
    final commentCount = ref.watch(allCommentsProvider).length;
    final liveChatCount = ref.watch(allLiveChatsProvider).length;
    final channelCount = ref.watch(channelsProvider).length;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final droppedComments = takeout.skippedCommentRows;
    final droppedLiveChats = takeout.skippedLiveChatRows;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            droppedComments > 0 || droppedLiveChats > 0
                ? Icons.warning_amber_outlined
                : Icons.check_circle_outline,
            size: 64,
            color: droppedComments > 0 || droppedLiveChats > 0
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('Import Complete', style: theme.textTheme.headlineSmall),
          if (droppedComments > 0 || droppedLiveChats > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Some rows could not be parsed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.comment_outlined,
                    label: 'Comments',
                    count: commentCount,
                    skippedCount: droppedComments,
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    icon: Icons.chat_bubble_outline,
                    label: 'Live Chats',
                    count: liveChatCount,
                    skippedCount: droppedLiveChats,
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    icon: Icons.people_outline,
                    label: 'Channels',
                    count: channelCount,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _viewChannels,
            icon: const Icon(Icons.list),
            label: Text(isAuthenticated ? 'View Channels' : 'Sign in to View Channels'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _import,
            icon: const Icon(Icons.refresh),
            label: const Text('Re-import'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final int skippedCount;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.count,
    this.skippedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text('$count $label'),
        if (skippedCount > 0) ...[
          const SizedBox(width: 8),
          Text(
            '($skippedCount skipped)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
