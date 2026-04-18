import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/deleted_ids_providers.dart';
import '../providers/deletion_queue_provider.dart';
import 'deletion_method_picker.dart';
import 'queue_snackbar.dart';

/// Shows the local-vs-API picker. If the user picks the API path, enqueues
/// each snippet map to the deletion queue and shows the "N item(s) queued"
/// snackbar. [onQueued] fires after successful enqueue.
void bulkDeleteViaPicker(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, String?> commentSnippets,
  required Map<String, String?> liveChatSnippets,
  VoidCallback? onQueued,
}) {
  final commentIds = commentSnippets.keys.toSet();
  final liveChatIds = liveChatSnippets.keys.toSet();
  final allIds = {...commentIds, ...liveChatIds};
  if (allIds.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No items to delete')));
    return;
  }
  final uncertainLiveChatCount = liveChatSnippets.values
      .where((s) => s == null || s.trim().isEmpty)
      .length;
  showDeletionMethodPicker(
    context,
    ref: ref,
    ids: allIds,
    uncertainLiveChatCount: uncertainLiveChatCount,
    onApiChosen: () {
      final queue = ref.read(deletionQueueProvider.notifier);
      if (commentIds.isNotEmpty) {
        queue.enqueueComments(commentIds, snippets: commentSnippets);
      }
      if (liveChatIds.isNotEmpty) {
        queue.enqueueLiveChats(liveChatIds, snippets: liveChatSnippets);
      }
      showQueuedForDeletionSnackBar(
        context,
        ref,
        message: Intl.plural(
          allIds.length,
          one: '1 item queued for deletion',
          other: '${allIds.length} items queued for deletion',
        ),
      );
      onQueued?.call();
    },
  );
}

/// Asks the user to confirm a purely-local removal of [commentIds] and
/// [liveChatIds] from the on-device list (no YouTube API call). Used for items
/// the user already deleted manually outside the app.
void confirmLocalDelete(
  BuildContext context,
  WidgetRef ref, {
  required Set<String> commentIds,
  required Set<String> liveChatIds,
  VoidCallback? onDone,
}) {
  final total = commentIds.length + liveChatIds.length;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove Items'),
      content: Text(
        '${Intl.plural(total, one: 'Remove 1 item', other: 'Remove $total items')} from the list?\n\n'
        'Use this for items you already deleted manually outside the app. '
        'This does not delete them from YouTube.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            if (commentIds.isNotEmpty) {
              ref.read(deletedCommentIdsProvider.notifier).markDeleted(commentIds);
            }
            if (liveChatIds.isNotEmpty) {
              ref.read(deletedLiveChatIdsProvider.notifier).markDeleted(liveChatIds);
            }
            onDone?.call();
          },
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

/// Thin wrapper over [bulkDeleteViaPicker] for a selection-sourced flow.
/// [onDone] fires after successful enqueue (not on cancel).
void confirmApiDelete(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, String?> commentSnippets,
  required Map<String, String?> liveChatSnippets,
  VoidCallback? onDone,
}) {
  bulkDeleteViaPicker(
    context,
    ref,
    commentSnippets: commentSnippets,
    liveChatSnippets: liveChatSnippets,
    onQueued: onDone,
  );
}
