import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_actions.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';

void toggleGroupSelection(
  WidgetRef ref,
  Set<String> groupItemIds,
  Set<String> ineligibleIds,
) {
  final eligible = groupItemIds.difference(ineligibleIds);
  if (eligible.isEmpty) return;
  final notifier = ref.read(deletionSetProvider.notifier);
  final selectedIds = ref.read(deletionSetProvider);
  final allSelected = eligible.difference(selectedIds).isEmpty;
  if (allSelected) {
    notifier.removeAll(eligible);
  } else {
    notifier.addAll(eligible);
  }
}

void showSingleItemActions(
  BuildContext context,
  WidgetRef ref, {
  required String itemId,
  required String displayText,
  required QueueItemKind kind,
  String? videoId,
  String? commentId,
  bool isQueued = false,
  bool isFailed = false,
}) {
  final isComment = kind == QueueItemKind.comment;

  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (videoId != null)
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open on YouTube'),
              onTap: () {
                Navigator.pop(ctx);
                final uri = commentId != null
                    ? Uri.https('www.youtube.com', '/watch', {
                        'v': videoId,
                        'lc': commentId,
                      })
                    : Uri.https('www.youtube.com', '/watch', {'v': videoId});
                launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          if (isFailed)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Retry'),
              subtitle: const Text('Re-queue for deletion'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(deletionQueueProvider.notifier)
                    .retryByItemId(itemId, kind);
              },
            ),
          if (isQueued || isFailed)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Remove from queue'),
              subtitle: const Text('Cancel the pending deletion'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(deletionQueueProvider.notifier)
                    .removeByItemId(itemId, kind);
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to deletion queue'),
              subtitle: const Text('Delete it from YouTube with the rest'),
              onTap: () {
                Navigator.pop(ctx);
                queueForDeletion(
                  context,
                  ref,
                  isComment
                      ? DeletionTargets(commentSnippets: {itemId: displayText})
                      : DeletionTargets(
                          liveChatSnippets: {itemId: displayText},
                        ),
                );
              },
            ),
          if (!isQueued && !isFailed)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove locally'),
              subtitle: const Text(
                'For comments you already deleted outside the app',
              ),
              onTap: () {
                Navigator.pop(ctx);
                showDialog<void>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Remove locally?'),
                    content: const Text(
                      'This only removes the item from your list. '
                      'It does not delete it from YouTube.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          if (isComment) {
                            ref
                                .read(deletedCommentIdsProvider.notifier)
                                .markDeleted({itemId});
                          } else {
                            ref
                                .read(deletedLiveChatIdsProvider.notifier)
                                .markDeleted({itemId});
                          }
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}
