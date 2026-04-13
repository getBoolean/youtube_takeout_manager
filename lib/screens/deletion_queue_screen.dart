import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/deletion_item_status.dart';
import '../models/deletion_queue_item.dart';
import '../providers/deletion_queue_provider.dart';
import '../widgets/deletion_queue_item_tile.dart';
import '../widgets/quota_status_bar.dart';

@RoutePage()
class DeletionQueueScreen extends ConsumerStatefulWidget {
  const DeletionQueueScreen({super.key});

  @override
  ConsumerState<DeletionQueueScreen> createState() =>
      _DeletionQueueScreenState();
}

class _DeletionQueueScreenState extends ConsumerState<DeletionQueueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['All', 'Pending', 'Completed', 'Failed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(deletionQueueProvider);
    final notifier = ref.read(deletionQueueProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deletion Queue'),
        actions: [
          if (queueAsync.value?.isNotEmpty == true)
            IconButton(
              icon: Icon(
                notifier.isProcessing && !notifier.isPaused
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              tooltip: notifier.isProcessing && !notifier.isPaused
                  ? 'Pause'
                  : 'Start',
              onPressed: () {
                if (notifier.isProcessing && !notifier.isPaused) {
                  notifier.pauseProcessing();
                } else {
                  notifier.startProcessing();
                }
                setState(() {});
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          const QuotaStatusBar(),
          _buildSummaryChips(queueAsync.value ?? []),
          const Divider(height: 1),
          Expanded(
            child: queueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) => TabBarView(
                controller: _tabController,
                children: [
                  _buildList(items),
                  _buildList(_filter(items, _pendingStatuses)),
                  _buildList(
                      _filter(items, {DeletionItemStatus.succeeded})),
                  _buildList(
                      _filter(items, _failedStatuses)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(queueAsync.value ?? []),
    );
  }

  static const _pendingStatuses = {
    DeletionItemStatus.pending,
    DeletionItemStatus.inProgress,
    DeletionItemStatus.quotaExceeded,
  };

  static const _failedStatuses = {
    DeletionItemStatus.failed,
    DeletionItemStatus.quotaExceeded,
  };

  List<DeletionQueueItem> _filter(
    List<DeletionQueueItem> items,
    Set<DeletionItemStatus> statuses,
  ) {
    return items.where((i) => statuses.contains(i.status)).toList();
  }

  Widget _buildSummaryChips(List<DeletionQueueItem> items) {
    final pending =
        items.where((i) => i.status == DeletionItemStatus.pending).length;
    final inProgress =
        items.where((i) => i.status == DeletionItemStatus.inProgress).length;
    final succeeded =
        items.where((i) => i.status == DeletionItemStatus.succeeded).length;
    final failed =
        items.where((i) => i.status == DeletionItemStatus.failed).length;
    final quotaExceeded =
        items.where((i) => i.status == DeletionItemStatus.quotaExceeded).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (pending > 0) _chip('Pending: $pending', Colors.grey),
          if (inProgress > 0) _chip('In Progress: $inProgress', Colors.blue),
          if (succeeded > 0) _chip('Completed: $succeeded', Colors.green),
          if (failed > 0) _chip('Failed: $failed', Colors.red),
          if (quotaExceeded > 0) _chip('Quota: $quotaExceeded', Colors.orange),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildList(List<DeletionQueueItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return DeletionQueueItemTile(
          item: item,
          onRemove: item.status != DeletionItemStatus.inProgress
              ? () => ref
                  .read(deletionQueueProvider.notifier)
                  .removeItem(item.id)
              : null,
        );
      },
    );
  }

  Widget? _buildBottomActions(List<DeletionQueueItem> items) {
    final hasFailed =
        items.any((i) => i.status == DeletionItemStatus.failed);
    final hasQuotaExceeded =
        items.any((i) => i.status == DeletionItemStatus.quotaExceeded);
    final hasCompleted =
        items.any((i) => i.status == DeletionItemStatus.succeeded);

    if (!hasFailed && !hasQuotaExceeded && !hasCompleted) return null;

    final notifier = ref.read(deletionQueueProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (hasFailed)
              FilledButton.tonalIcon(
                onPressed: () => notifier.retryFailed(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Failed'),
              ),
            if (hasQuotaExceeded)
              FilledButton.tonalIcon(
                onPressed: () => notifier.retryQuotaExceeded(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Quota'),
              ),
            if (hasCompleted)
              OutlinedButton.icon(
                onPressed: () => notifier.clearCompleted(),
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Completed'),
              ),
          ],
        ),
      ),
    );
  }
}
