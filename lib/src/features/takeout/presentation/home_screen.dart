import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_flow.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../application/takeout_notifier.dart';
import '../application/takeout_selection_notifier.dart';
import '../application/viewed_takeout_providers.dart';
import '../data/zip_picker_repository.dart';
import '../domain/takeout_data.dart';
import '../domain/takeout_import_plan.dart';
import 'channel_picker_dialog.dart';
import 'import_confirm_dialog.dart';
import 'import_error_dialog.dart';
import 'import_progress_indicator.dart';
import 'queue_summary_card.dart';
import 'takeout_switcher.dart';

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

      final previousChannel = ref.read(viewedChannelIdProvider);
      await notifier.commitImport(plan);
      if (!mounted) return;
      if (merge) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(_addedSummary(plan))));
        return;
      }
      // A takeout with several channels, none of them the one viewed
      // before, asks which to view. Dismissing keeps its main channel.
      if (plan.channels.length > 1 &&
          !plan.channels.any((c) => c.channelId == previousChannel)) {
        final picked = await showDialog<String>(
          context: context,
          builder: (_) => ChannelPickerDialog(
            channels: plan.channels,
            viewedChannelId: plan.channels.first.channelId,
            signedInChannelIds: {
              ...?ref.read(savedSignInsProvider).value?.keys,
            },
          ),
        );
        if (picked != null) {
          await ref
              .read(takeoutSelectionProvider.notifier)
              .selectChannel(picked);
        }
        if (!mounted) return;
      }
      await _viewChannels();
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
    final takeoutAsync = ref.watch(viewedTakeoutProvider);
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
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Select one or more takeout zip files',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => _import(merge: false),
          icon: const Icon(Icons.folder_open),
          label: const Text('Select Zip Files', textAlign: TextAlign.center),
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
        Text(
          'Failed to load saved data',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => _import(merge: false),
          icon: const Icon(Icons.folder_open),
          label: const Text('Import New Data', textAlign: TextAlign.center),
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
    final viewed = ref.watch(viewedChannelProvider);
    final channels = ref.watch(takeoutChannelsProvider);
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
          Text(
            viewed?.title ?? viewed?.channelId ?? 'Import Complete',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          if (viewed != null && channels.length > 1) ...[
            const SizedBox(height: 4),
            Text(
              '${channels.indexOf(viewed) + 1} of ${channels.length} channels',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton.icon(
              onPressed: () => changeChannel(context, ref),
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Change channel', textAlign: TextAlign.center),
            ),
          ],
          if (droppedComments > 0 || droppedLiveChats > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Some rows could not be parsed',
              textAlign: TextAlign.center,
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
          QueueSummaryCard(onOpenChannels: _viewChannels),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _viewChannels,
            icon: const Icon(Icons.list),
            label: const Text('View Channels', textAlign: TextAlign.center),
          ),
          if (!isAuthenticated) ...[
            const SizedBox(height: 8),
            Text(
              'Signed out: video titles and YouTube API deletion are off.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton.icon(
              onPressed: isOAuthConfigured
                  ? () => signInToViewedChannel(context, ref)
                  : null,
              icon: const Icon(Icons.login),
              label: const Text('Sign in', textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => _import(merge: true),
            icon: const Icon(Icons.library_add_outlined),
            label: const Text('Add Newer Takeout', textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _import(merge: false),
            icon: const Icon(Icons.refresh),
            label: const Text('Replace Data', textAlign: TextAlign.center),
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
        // Left out in the narrowest windows so the text still fits.
        if (MediaQuery.sizeOf(context).width >= 160) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        // One text, so it wraps instead of overflowing when narrow.
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$count $label'),
                if (skippedCount > 0)
                  TextSpan(
                    text: '  ($skippedCount skipped)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
