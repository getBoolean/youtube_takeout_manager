import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/deletion_targets.dart';
import 'deletion_actions.dart';

/// Two-button bottom bar shown when selection mode has items picked: remove
/// the selection locally, or delete it from YouTube.
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
                child: FilledButton.icon(
                  onPressed: () async {
                    final removed = await confirmLocalRemoval(
                      context,
                      ref,
                      commentIds: selection.commentIds,
                      liveChatIds: selection.liveChatIds,
                    );
                    if (removed) onExitSelection();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text('Remove $total locally'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  final handedOff = await deleteFromYouTube(
                    context,
                    ref,
                    selection,
                  );
                  if (handedOff) onExitSelection();
                },
                icon: const Icon(Icons.cloud_off),
                label: Text('Delete $total from YouTube'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
