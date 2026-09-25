import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/deletion_targets.dart';
import 'deletion_actions.dart';

/// Bottom bar shown when selection mode has items picked: queue the selection
/// for deletion, or remove it from the list only.
class SelectionActionBar extends ConsumerWidget {
  final DeletionTargets selection;
  final VoidCallback onExitSelection;

  const SelectionActionBar({
    super.key,
    required this.selection,
    required this.onExitSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = selection.count;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Tooltip(
                message: 'For items you already deleted outside the app',
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final removed = await confirmLocalRemoval(
                      context,
                      ref,
                      commentIds: selection.commentIds,
                      liveChatIds: selection.liveChatIds,
                    );
                    if (removed) onExitSelection();
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  label: Text('Remove $total locally'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  final queued = await queueForDeletion(
                    context,
                    ref,
                    selection,
                  );
                  if (queued) onExitSelection();
                },
                icon: const Icon(Icons.playlist_add),
                label: Text('Queue $total for deletion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
