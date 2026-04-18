import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'bulk_delete_actions.dart';

/// Two-button bottom bar shown when selection mode has items picked. Drives
/// the local-remove vs API-queue split for both per-channel and cross-channel
/// selection flows.
class SelectionActionBar extends ConsumerWidget {
  final Set<String> commentIds;
  final Set<String> liveChatIds;
  final Map<String, String?> commentSnippets;
  final Map<String, String?> liveChatSnippets;
  final VoidCallback onExitSelection;

  const SelectionActionBar({
    super.key,
    required this.commentIds,
    required this.liveChatIds,
    required this.commentSnippets,
    required this.liveChatSnippets,
    required this.onExitSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticated = ref.watch(isAuthenticatedProvider);
    final total = commentIds.length + liveChatIds.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Tooltip(
                message: 'For items you already deleted outside the app',
                child: FilledButton.icon(
                  onPressed: () => confirmLocalDelete(
                    context,
                    ref,
                    commentIds: commentIds,
                    liveChatIds: liveChatIds,
                    onDone: onExitSelection,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text('Remove $total locally'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ),
            if (authenticated) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => confirmApiDelete(
                    context,
                    ref,
                    commentSnippets: commentSnippets,
                    liveChatSnippets: liveChatSnippets,
                    onDone: onExitSelection,
                  ),
                  icon: const Icon(Icons.cloud_off),
                  label: Text('Delete $total from YouTube'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
