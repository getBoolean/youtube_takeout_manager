import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/comment_providers.dart';
import '../providers/channel_providers.dart';
import '../providers/live_chat_providers.dart';
import '../providers/takeout_providers.dart';
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
      await ref.read(takeoutProvider.notifier).importFiles();
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final takeout = ref.watch(takeoutProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Takeout Manager'),
      ),
      body: Center(
        child: _importing
            ? const ImportProgressIndicator()
            : takeout == null
                ? _buildImportPrompt(theme)
                : _buildSummary(context, theme),
      ),
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

  Widget _buildSummary(BuildContext context, ThemeData theme) {
    final commentCount = ref.watch(allCommentsProvider).length;
    final liveChatCount = ref.watch(allLiveChatsProvider).length;
    final channelCount = ref.watch(channelsProvider).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text('Import Complete', style: theme.textTheme.headlineSmall),
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
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.chat_bubble_outline,
                  label: 'Live Chats',
                  count: liveChatCount,
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
          onPressed: () => context.router.push(const ChannelListRoute()),
          icon: const Icon(Icons.list),
          label: const Text('View Channels'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _import,
          icon: const Icon(Icons.refresh),
          label: const Text('Re-import'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text('$count $label'),
      ],
    );
  }
}
