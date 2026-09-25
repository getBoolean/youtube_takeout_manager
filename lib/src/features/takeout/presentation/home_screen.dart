import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../application/takeout_notifier.dart';
import '../data/zip_picker_repository.dart';
import '../domain/takeout_data.dart';
import '../domain/takeout_import_plan.dart';
import 'import_confirm_dialog.dart';
import 'import_error_dialog.dart';
import 'import_progress_indicator.dart';
import 'queue_summary_card.dart';

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _importing = false;

  /// Imports picked takeout zips. [merge] adds them to the saved data
  /// instead of replacing it.
  Future<void> _import({required bool merge}) async {
    // Pick files directly from the click handler — browsers require the file
    // input to be triggered within the user gesture context. Going through
    // setState or async Riverpod hops first can break this on web.
    final result = await ref.read(zipPickerRepositoryProvider).pickZips();
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final saved = ref.read(takeoutProvider);
    final hasSavedData = saved.value != null;
    final savedDataUnreadable = saved.hasError;
    setState(() => _importing = true);
    try {
      final notifier = ref.read(takeoutProvider.notifier);
      final plan = await notifier.prepareImport(result, merge: merge);
      // Replacing can overwrite the takeout account's saved data even when
      // another account's data is shown.
      final replacesSavedData =
          !merge && await notifier.hasSavedData(plan.accountId);
      if (!mounted) return;

      if (hasSavedData ||
          savedDataUnreadable ||
          replacesSavedData ||
          _needsReview(plan)) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => ImportConfirmDialog(
            plan: plan,
            merge: merge,
            hasSavedData: hasSavedData,
            replacesSavedData: replacesSavedData,
            savedDataUnreadable: savedDataUnreadable,
          ),
        );
        if (confirmed != true || !mounted) return;
      }

      await notifier.commitImport(plan);
      if (!mounted) return;
      if (merge) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(_addedSummary(plan))));
        return;
      }
      if (ref.read(authProvider) == null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Sign in to fetch video metadata and view channels.',
              ),
            ),
          );
        return;
      }
      await ref.read(channelThumbnailsProvider.notifier).loadCache();
      if (mounted) context.router.push(const ChannelListRoute());
    } on TakeoutImportException catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => ImportErrorDialog(error: e),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// Whether a first import still needs a look before it's saved.
  bool _needsReview(TakeoutImportPlan plan) =>
      plan.newlyDeletedCommentCount > 0 ||
      plan.newlyDeletedLiveChatCount > 0 ||
      plan.commentCheckSkipped != null ||
      plan.liveChatCheckSkipped != null ||
      plan.mergedData.skippedCommentRows > 0 ||
      plan.mergedData.skippedLiveChatRows > 0;

  String _addedSummary(TakeoutImportPlan plan) {
    String count(int n, String noun) => '$n ${n == 1 ? noun : '${noun}s'}';
    final deleted = [
      if (plan.newlyDeletedCommentCount > 0)
        count(plan.newlyDeletedCommentCount, 'comment'),
      if (plan.newlyDeletedLiveChatCount > 0)
        count(plan.newlyDeletedLiveChatCount, 'live chat'),
    ];
    return 'Added ${count(plan.newCommentCount, 'comment')} and '
        '${count(plan.newLiveChatCount, 'live chat')}.'
        '${deleted.isEmpty ? '' : ' Marked ${deleted.join(' and ')} deleted.'}';
  }

  @override
  Widget build(BuildContext context) {
    final takeoutAsync = ref.watch(takeoutProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Takeout Manager'),
        actions: const [AccountButton()],
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

  Widget _buildImportPrompt(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.upload_file, size: 80, color: theme.colorScheme.primary),
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
          onPressed: () => _import(merge: false),
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
          onPressed: () => _import(merge: false),
          icon: const Icon(Icons.folder_open),
          label: const Text('Import New Data'),
        ),
      ],
    );
  }

  Future<void> _viewChannels() async {
    await ref.read(channelThumbnailsProvider.notifier).loadCache();
    if (mounted) context.router.push(const ChannelListRoute());
  }

  Widget _buildSummary(
    BuildContext context,
    ThemeData theme,
    TakeoutData takeout,
  ) {
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
          const SizedBox(height: 16),
          QueueSummaryCard(
            onOpenChannels: isAuthenticated ? _viewChannels : null,
          ),
          const SizedBox(height: 16),
          if (isAuthenticated)
            FilledButton.icon(
              onPressed: _viewChannels,
              icon: const Icon(Icons.list),
              label: const Text('View Channels'),
            )
          else
            FilledButton.icon(
              onPressed: isOAuthConfigured
                  ? () => ref.read(authProvider.notifier).signIn()
                  : null,
              icon: const Icon(Icons.login),
              label: const Text('Sign in to View Channels'),
            ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => _import(merge: true),
            icon: const Icon(Icons.library_add_outlined),
            label: const Text('Add Newer Takeout'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _import(merge: false),
            icon: const Icon(Icons.refresh),
            label: const Text('Replace Data'),
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
