import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_counts.dart';

/// Home's note of items still waiting or failed in the deletion queue, which
/// lives beside the channel lists. Hidden when there are none.
class QueueSummaryCard extends ConsumerWidget {
  /// Opens the channel lists, or null when they can't be opened yet.
  final VoidCallback? onOpenChannels;

  const QueueSummaryCard({super.key, required this.onOpenChannels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(deletionQueueCountsProvider);
    if (counts.waiting == 0 && counts.failed == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final parts = [
      if (counts.waiting > 0)
        Intl.plural(
          counts.waiting,
          one: '1 item waiting to be deleted',
          other: '${counts.waiting} items waiting to be deleted',
        ),
      if (counts.failed > 0) '${counts.failed} failed',
    ];

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        // The button moves under the text when there isn't room beside it.
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_sweep_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(parts.join(' · '), textAlign: TextAlign.center),
                ),
              ],
            ),
            if (onOpenChannels case final open?)
              TextButton(
                onPressed: open,
                child: const Text('Open channels', textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}
