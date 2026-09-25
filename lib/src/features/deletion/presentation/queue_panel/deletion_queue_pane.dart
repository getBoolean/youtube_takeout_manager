import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import '../../application/deletion_queue_counts.dart';
import '../../application/deletion_queue_notifier.dart';
import 'deletion_queue_layout.dart';
import 'deletion_queue_panel.dart';

const deletionQueuePaneWidth = 360.0;
const _stripWidth = 48.0;

/// The queue docked beside the screen, or the strip it collapses to.
class DeletionQueuePane extends ConsumerWidget {
  final String? currentChannelId;

  const DeletionQueuePane({super.key, this.currentChannelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(deletionQueuePaneExpandedProvider);
    final pane = ref.read(deletionQueuePaneExpandedProvider.notifier);
    if (!expanded) return DeletionQueueStrip(onOpen: () => pane.set(true));

    return SizedBox(
      width: deletionQueuePaneWidth,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: SafeArea(
          left: false,
          child: DeletionQueuePanel(
            currentChannelId: currentChannelId,
            headerAction: IconButton(
              icon: const Icon(Icons.keyboard_double_arrow_right),
              tooltip: 'Collapse',
              onPressed: () => pane.set(false),
            ),
          ),
        ),
      ),
    );
  }
}

/// A slim full-height column beside the screen that opens the queue:
/// [onOpen], or the queue's side sheet by default.
class DeletionQueueStrip extends ConsumerWidget {
  final String? currentChannelId;
  final VoidCallback? onOpen;

  const DeletionQueueStrip({super.key, this.currentChannelId, this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running =
        ref.watch(deletionProcessingProvider) != DeletionProcessingState.idle;
    final open =
        onOpen ??
        () => showDeletionQueueSideSheet(
          context,
          currentChannelId: currentChannelId,
        );

    return SizedBox(
      width: _stripWidth,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: open,
          child: SafeArea(
            left: false,
            child: Column(
              children: [
                // Lines the icon up with the app bar's.
                SizedBox(
                  height: kToolbarHeight,
                  child: Center(
                    child: DeletionQueueIconButton(onPressed: open),
                  ),
                ),
                if (running)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The queue icon, badged with the number of items waiting to be deleted.
/// Opens the queue's side sheet unless [onPressed] is given.
class DeletionQueueIconButton extends ConsumerWidget {
  final String? currentChannelId;
  final VoidCallback? onPressed;

  const DeletionQueueIconButton({
    super.key,
    this.currentChannelId,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(
      deletionQueueCountsProvider.select((c) => c.waiting),
    );
    return IconButton(
      tooltip: 'Deletion queue',
      onPressed:
          onPressed ??
          () => showDeletionQueueSideSheet(
            context,
            currentChannelId: currentChannelId,
          ),
      icon: Badge(
        isLabelVisible: waiting > 0,
        // Capped so a big queue doesn't cover the next button.
        label: waiting > 999
            ? const Text('999+')
            : AnimatedCountText(waiting, style: const TextStyle(fontSize: 11)),
        child: const Icon(Icons.delete_sweep_outlined),
      ),
    );
  }
}
