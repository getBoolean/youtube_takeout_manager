import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../domain/deletion_targets.dart';
import '../domain/my_activity_results.dart';
import 'deleted_ids_providers.dart';
import 'deletion_processing.dart';
import 'deletion_queue_notifier.dart';
import 'script_deletion_ids.dart';

part 'deletion_service.g.dart';

/// The viewed channel's items the next Delete takes, and how many of them
/// may be membership events that won't delete.
typedef WaitingDeletion = ({
  String channelId,
  DeletionTargets targets,
  int possibleMembershipEvents,
});

/// Queues items for deletion, removes them locally, and starts deleting
/// them. A service: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class DeletionService extends _$DeletionService {
  @override
  void build() {}

  /// Adds [targets] to the deletion queue, where the user later picks how
  /// to delete them. Returns false if no channel is viewed.
  Future<bool> queue(DeletionTargets targets) async {
    // Everything on screen is the viewed channel's, so it wrote them.
    final channelId = ref.read(viewedChannelIdProvider);
    if (channelId == null) return false;
    await ref
        .read(deletionQueueProvider.notifier)
        .enqueue(targets, authorChannelId: channelId);
    return true;
  }

  /// Marks [targets] deleted without deleting them from YouTube, for items
  /// already deleted outside the app.
  Future<void> removeLocally(DeletionTargets targets) =>
      ref.read(deletedIdsProvider.notifier).markDeleted(targets);

  /// The viewed channel's items the next Delete takes, or null if none.
  WaitingDeletion? waiting() {
    final channelId = ref.read(viewedChannelIdProvider);
    if (channelId == null) return null;
    final targets = DeletionTargets.fromQueueItems(
      ref.read(deletionQueueProvider.notifier).pendingItemsFor(channelId),
    );
    if (targets.isEmpty) return null;
    final liveChats = ref.read(viewedTakeoutProvider).value?.liveChats;
    return (
      channelId: channelId,
      targets: targets,
      possibleMembershipEvents: targets.possibleMembershipEventsIn(
        liveChats ?? const [],
      ),
    );
  }

  /// Hands [targets] to the My Activity script screen.
  void useMyActivityScript(DeletionTargets targets) =>
      ref.read(scriptDeletionIdsProvider.notifier).set(targets);

  /// Starts deleting [channelId]'s waiting items via the YouTube API. Runs
  /// until the queue is done, paused or out of quota.
  void startYoutubeApiDeletion(String channelId) => unawaited(
    ref
        .read(deletionProcessingProvider.notifier)
        .processPendingViaYoutubeApi(channelId: channelId),
  );

  /// Records a My Activity script run over [targets]: marks what it deleted
  /// as deleted, under each item's own kind, and updates the queue. IDs
  /// outside [targets], e.g. from older results pasted again, are left
  /// alone, so the queue and the deleted items agree.
  Future<void> recordMyActivityResults(
    DeletionTargets targets,
    MyActivityResults results,
  ) async {
    final ids = targets.allIds;
    await ref
        .read(deletedIdsProvider.notifier)
        .markDeleted(
          DeletionTargets.ids({
            for (final kind in QueueItemKind.values)
              kind: targets.idsOf(kind).intersection(results.deleted),
          }),
        );
    await ref
        .read(deletionQueueProvider.notifier)
        .recordMyActivityResults(
          deletedIds: results.deleted.intersection(ids),
          errorsById: {
            for (final MapEntry(:key, :value) in results.errorsById.entries)
              if (ids.contains(key)) key: value,
          },
        );
  }
}
