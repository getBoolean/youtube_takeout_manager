import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/deletion_item_status.dart';
import '../providers/deletion_queue_provider.dart';
import '../router/app_router.dart';
import 'cue_motion.dart';

/// App bar button that opens the deletion queue, badged with the number of
/// items still waiting to be deleted.
class DeletionQueueButton extends ConsumerWidget {
  const DeletionQueueButton({super.key});

  static const _waitingStatuses = {
    DeletionItemStatus.pending,
    DeletionItemStatus.inProgress,
    DeletionItemStatus.quotaExceeded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(deletionQueueProvider).value ?? const [];
    final waitingCount = items
        .where((i) => _waitingStatuses.contains(i.status))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Badge(
        isLabelVisible: waitingCount > 0,
        label: AnimatedCountText(
          waitingCount,
          style: const TextStyle(fontSize: 12),
        ),
        child: FilledButton.tonalIcon(
          onPressed: () => context.router.push(const DeletionQueueRoute()),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Deletion Queue'),
        ),
      ),
    );
  }
}
