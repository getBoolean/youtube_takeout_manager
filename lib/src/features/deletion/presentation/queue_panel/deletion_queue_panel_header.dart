import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';

/// The queue's title, with how many items it holds and [action].
class DeletionQueuePanelHeader extends StatelessWidget {
  final int count;
  final Widget? action;

  const DeletionQueuePanelHeader({
    super.key,
    required this.count,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // App bar height, so the title lines up with the screen's beside it.
    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
        child: Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Deletion queue', style: theme.textTheme.titleMedium),
            ),
            if (count > 0)
              AnimatedCountText(
                count,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 4),
            ?action,
          ],
        ),
      ),
    );
  }
}
