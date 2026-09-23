import 'package:auto_route/auto_route.dart';
import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/deletion_item_status.dart';
import '../models/deletion_method.dart';
import '../models/deletion_queue_item.dart';
import '../models/deletion_targets.dart';
import '../providers/auth_providers.dart';
import '../providers/deletion_queue_provider.dart';
import '../widgets/cue_motion.dart';
import '../widgets/deletion_actions.dart';
import '../widgets/deletion_method_picker.dart';
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

  /// Items the user has tapped remove on but whose exit animation is still
  /// playing. Kept so the tile stays rendered as the animation reverses; the
  /// actual provider removal happens when the animation ends.
  final Set<String> _removingIds = {};

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
          if (_isRunning)
            IconButton(
              icon: const Icon(Icons.pause),
              tooltip: 'Pause',
              onPressed: () {
                notifier.pauseProcessing();
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
                  _buildList(_filter(items, {DeletionItemStatus.succeeded})),
                  _buildList(_filter(items, _failedStatuses)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(queueAsync.value ?? []),
    );
  }

  bool get _isRunning {
    final notifier = ref.read(deletionQueueProvider.notifier);
    return notifier.isProcessing && !notifier.isPaused;
  }

  /// Asks how to delete the pending items, then starts that method.
  Future<void> _processQueue() async {
    final notifier = ref.read(deletionQueueProvider.notifier);
    final pending = DeletionTargets.fromQueueItems(notifier.pendingItems);
    final method = await pickDeletionMethod(
      context,
      title: Intl.plural(
        pending.count,
        one: 'Process 1 queued item',
        other: 'Process ${pending.count} queued items',
      ),
      itemCount: pending.count,
      possibleMembershipEventCount: pending.possibleMembershipEventCount,
      offerAddToQueue: false,
      youtubeApiAvailable: ref.read(isAuthenticatedProvider),
    );
    if (!mounted) return;

    switch (method) {
      case DeletionMethod.myActivityScript:
        openMyActivityScript(context, ref, pending.allIds);
      case DeletionMethod.youtubeApi:
        final processing = notifier.processPendingViaYoutubeApi();
        setState(() {});
        await processing;
        if (mounted) setState(() {});
      case DeletionMethod.addToQueue || null:
        return;
    }
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
    final pending = items
        .where((i) => i.status == DeletionItemStatus.pending)
        .length;
    final inProgress = items
        .where((i) => i.status == DeletionItemStatus.inProgress)
        .length;
    final succeeded = items
        .where((i) => i.status == DeletionItemStatus.succeeded)
        .length;
    final failed = items
        .where((i) => i.status == DeletionItemStatus.failed)
        .length;
    final quotaExceeded = items
        .where((i) => i.status == DeletionItemStatus.quotaExceeded)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _AnimatedStatusChip(
            label: 'Pending',
            count: pending,
            color: Colors.grey,
          ),
          _AnimatedStatusChip(
            label: 'In Progress',
            count: inProgress,
            color: Colors.blue,
          ),
          _AnimatedStatusChip(
            label: 'Completed',
            count: succeeded,
            color: Colors.green,
          ),
          _AnimatedStatusChip(
            label: 'Failed',
            count: failed,
            color: Colors.red,
          ),
          _AnimatedStatusChip(
            label: 'Quota',
            count: quotaExceeded,
            color: Colors.orange,
          ),
        ],
      ),
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
        final isRemoving = _removingIds.contains(item.id);
        final motion = premiumSpring(context);
        return Cue.onToggle(
          key: ValueKey(item.id),
          toggled: !isRemoving,
          motion: motion,
          reverseMotion: motion,
          acts: const [
            ClipAct.height(),
            OpacityAct.fadeIn(),
            SlideAct.x(from: 1.0),
          ],
          onEnd: (visible) {
            if (!visible && mounted && _removingIds.contains(item.id)) {
              ref.read(deletionQueueProvider.notifier).removeItem(item.id);
              setState(() => _removingIds.remove(item.id));
            }
          },
          child: DeletionQueueItemTile(
            item: item,
            onRemove: item.status != DeletionItemStatus.inProgress
                ? () {
                    if (_removingIds.contains(item.id)) return;
                    setState(() => _removingIds.add(item.id));
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget? _buildBottomActions(List<DeletionQueueItem> items) {
    final hasFailed = items.any((i) => i.status == DeletionItemStatus.failed);
    final hasQuotaExceeded = items.any(
      (i) => i.status == DeletionItemStatus.quotaExceeded,
    );
    final hasCompleted = items.any(
      (i) => i.status == DeletionItemStatus.succeeded,
    );
    final canProcess =
        !_isRunning &&
        items.any(
          (i) =>
              i.status == DeletionItemStatus.pending ||
              i.status == DeletionItemStatus.quotaExceeded,
        );

    if (!canProcess && !hasFailed && !hasQuotaExceeded && !hasCompleted) {
      return null;
    }

    final notifier = ref.read(deletionQueueProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (canProcess)
              FilledButton.icon(
                onPressed: _processQueue,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Process Queue'),
              ),
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

class _AnimatedStatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AnimatedStatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final motion = premiumSpring(context);
    return Cue.onToggle(
      toggled: count > 0,
      motion: motion,
      reverseMotion: motion,
      acts: const [ClipAct.width(), OpacityAct.fadeIn(), ScaleAct(from: 0.8)],
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: TextStyle(color: color, fontSize: 12)),
            AnimatedCountText(
              count,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: color.withValues(alpha: 0.1),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
