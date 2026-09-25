import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/deletion_queue_counts.dart';
import '../../application/deletion_queue_notifier.dart';
import 'deletion_queue_layout.dart';

/// Phones' bottom bar summarizing the deletion queue. Tapping it opens the
/// queue as a bottom sheet. Hidden while the queue is empty.
class DeletionQueueSummaryBar extends ConsumerWidget {
  final String? currentChannelId;

  const DeletionQueueSummaryBar({super.key, this.currentChannelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(deletionQueueCountsProvider);
    final running =
        ref.watch(deletionProcessingProvider) != DeletionProcessingState.idle;
    if (counts.total == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final parts = [
      if (counts.waiting > 0) '${counts.waiting} waiting',
      if (counts.failed > 0) '${counts.failed} failed',
      if (counts.waiting == 0 && counts.failed == 0) '${counts.done} deleted',
    ];

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () =>
            showDeletionQueueSheet(context, currentChannelId: currentChannelId),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (running) const LinearProgressIndicator(minHeight: 2),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Deletion queue · ${parts.join(' · ')}',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.expand_less),
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
