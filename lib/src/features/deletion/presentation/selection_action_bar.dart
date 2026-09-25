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
    final removeButton = Tooltip(
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
        label: Text('Remove $total locally', overflow: TextOverflow.ellipsis),
      ),
    );
    final queueButton = FilledButton.icon(
      onPressed: () async {
        final queued = await queueForDeletion(context, ref, selection);
        if (queued) onExitSelection();
      },
      icon: const Icon(Icons.playlist_add),
      label: Text('Queue $total for deletion', overflow: TextOverflow.ellipsis),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        // Too narrow for both side by side: stack them, primary on top.
        child: MediaQuery.sizeOf(context).width < _sideBySideMinWidth
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  queueButton,
                  const SizedBox(height: 8),
                  removeButton,
                ],
              )
            : Row(
                children: [
                  Expanded(child: removeButton),
                  const SizedBox(width: 8),
                  Expanded(child: queueButton),
                ],
              ),
      ),
    );
  }

  static const _sideBySideMinWidth = 360.0;
}
