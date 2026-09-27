import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/common_widgets/actions_sheet.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_actions.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/youtube_links.dart';

/// What can be done with one comment or live chat from its actions sheet.
enum ItemAction { openOnYouTube, retry, removeFromQueue, queue, removeLocally }

/// Offers what can be done with [item], given its [status]. Returns the pick,
/// or null if the sheet was dismissed.
Future<ItemAction?> showItemActionsSheet(
  BuildContext context, {
  required Interaction item,
  required InteractionStatus status,
}) {
  final inQueue =
      status == InteractionStatus.queued || status == InteractionStatus.failed;
  final kindName = switch (item.kind) {
    QueueItemKind.comment => 'comments',
    QueueItemKind.liveChat => 'live chats',
  };

  return showActionsSheet(
    context,
    options: [
      if (item.videoId != null)
        SheetOption(
          ItemAction.openOnYouTube,
          Icons.open_in_new,
          'Open on YouTube',
        ),
      if (status == InteractionStatus.failed)
        SheetOption(
          ItemAction.retry,
          Icons.refresh,
          'Retry',
          'Re-queue for deletion',
        ),
      if (inQueue)
        SheetOption(
          ItemAction.removeFromQueue,
          Icons.remove_circle_outline,
          'Remove from queue',
          'Cancel the pending deletion',
        )
      else ...[
        SheetOption(
          ItemAction.queue,
          Icons.playlist_add,
          'Add to deletion queue',
          'Delete it from YouTube with the rest',
        ),
        SheetOption(
          ItemAction.removeLocally,
          Icons.delete_outline,
          'Remove locally',
          'For $kindName you already deleted outside the app',
        ),
      ],
    ],
  );
}

/// Does [action] to [item].
Future<void> runItemAction(
  BuildContext context,
  WidgetRef ref,
  Interaction item,
  ItemAction action,
) async {
  switch (action) {
    case ItemAction.openOnYouTube:
      if (item.videoId == null) return;
      final uri = youtubeUrlOf(item);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    case ItemAction.retry:
      await ref
          .read(deletionQueueProvider.notifier)
          .retryByItemId(item.id, item.kind);
    case ItemAction.removeFromQueue:
      await ref
          .read(deletionQueueProvider.notifier)
          .removeByItemId(item.id, item.kind);
    case ItemAction.queue:
      await queueForDeletion(context, ref, DeletionTargets.of([item]));
    case ItemAction.removeLocally:
      await confirmLocalRemoval(context, ref, DeletionTargets.of([item]));
  }
}
