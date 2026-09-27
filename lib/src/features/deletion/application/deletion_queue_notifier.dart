import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import '../data/deletion_queue_repository.dart';
import '../domain/deletion_item_status.dart';
import '../domain/deletion_queue_item.dart';
import '../domain/deletion_targets.dart';

part 'deletion_queue_notifier.g.dart';

/// The items queued to be deleted, kept on this device. Deleting them
/// through the YouTube API is `DeletionProcessing`'s.
@Riverpod(keepAlive: true)
class DeletionQueue extends _$DeletionQueue {
  DeletionQueueRepository get _repository =>
      ref.read(deletionQueueRepositoryProvider);

  @override
  Future<List<DeletionQueueItem>> build() async {
    return ref.watch(deletionQueueRepositoryProvider).loadQueue();
  }

  /// [channelId]'s items still waiting to be deleted, including those
  /// stopped by the quota, but not the one being deleted.
  List<DeletionQueueItem> pendingItemsFor(String channelId) => [
    for (final i in state.value ?? const <DeletionQueueItem>[])
      if (i.authorChannelId == channelId && i.status.isReadyToDelete) i,
  ];

  // ---------------------------------------------------------------------------
  // Enqueue
  // ---------------------------------------------------------------------------

  /// Queues [targets], written by [authorChannelId].
  Future<void> enqueue(
    DeletionTargets targets, {
    required String authorChannelId,
  }) async {
    await _enqueue(
      QueueItemKind.comment,
      targets.commentSnippets,
      authorChannelId,
    );
    await _enqueue(
      QueueItemKind.liveChat,
      targets.liveChatSnippets,
      authorChannelId,
    );
  }

  Future<void> _enqueue(
    QueueItemKind type,
    Map<String, String?> snippets,
    String authorChannelId,
  ) => _update((current) {
    final existingItemIds = current
        .where((i) => i.itemType == type)
        .map((i) => i.itemId)
        .toSet();
    final newIds = snippets.keys.toSet().difference(existingItemIds);
    if (newIds.isEmpty) return current;

    final now = DateTime.now().toUtc();
    final newItems = newIds.map((id) {
      final snippet = snippets[id];
      return DeletionQueueItem(
        id: _generateId(),
        itemId: id,
        itemType: type,
        status: DeletionItemStatus.pending,
        displayTextSnippet: snippet != null && snippet.length > 80
            ? '${snippet.substring(0, 80)}...'
            : snippet,
        createdAt: now,
        authorChannelId: authorChannelId,
      );
    }).toList();

    return [...current, ...newItems];
  });

  // ---------------------------------------------------------------------------
  // Item management
  // ---------------------------------------------------------------------------

  Future<void> retryFailed({required String channelId}) async {
    await _resetItemsByStatus(DeletionItemStatus.failed, channelId);
  }

  Future<void> retryQuotaExceeded({required String channelId}) async {
    await _resetItemsByStatus(DeletionItemStatus.quotaExceeded, channelId);
  }

  /// Clears [channelId]'s deleted items, and deleted items whose channel
  /// isn't known.
  Future<void> clearCompleted({required String channelId}) => _update(
    (current) => current
        .where(
          (i) =>
              !i.status.isDone ||
              (i.authorChannelId != null && i.authorChannelId != channelId),
        )
        .toList(),
  );

  /// Removes every item written by [channelIds], e.g. when their takeout
  /// is removed.
  Future<void> removeForChannels(Set<String> channelIds) => _update(
    (current) =>
        current.where((i) => !channelIds.contains(i.authorChannelId)).toList(),
  );

  /// Removes items queued before their channel was saved that no takeout
  /// has matched to one, and that aren't done.
  Future<void> removeUnassigned() => _update(
    (current) => current
        .where((i) => i.authorChannelId != null || i.status.isDone)
        .toList(),
  );

  /// Fills in the channel of items queued before it was saved, from the
  /// authors of a loaded takeout's comments and live chats, by item ID.
  Future<void> assignMissingChannels({
    required Map<String, String> commentAuthors,
    required Map<String, String> liveChatAuthors,
  }) => _update(
    (current) => current.map((i) {
      if (i.authorChannelId != null) return i;
      final authors = i.itemType == QueueItemKind.comment
          ? commentAuthors
          : liveChatAuthors;
      final author = authors[i.itemId];
      return author != null ? i.copyWith(authorChannelId: author) : i;
    }).toList(),
  );

  Future<void> removeItem(String queueItemId) =>
      _update((current) => current.where((i) => i.id != queueItemId).toList());

  Future<void> removeByItemId(String itemId, QueueItemKind kind) => _update(
    (current) => current
        .where((i) => !(i.itemId == itemId && i.itemType == kind))
        .toList(),
  );

  /// Removes entries for [itemIds] that are waiting or failed, e.g. because
  /// the items are already gone from YouTube. In-progress and succeeded
  /// entries are kept.
  Future<void> dropUnprocessed(Set<String> itemIds, QueueItemKind kind) =>
      _update(
        (current) => current
            .where(
              (i) =>
                  !(i.itemType == kind &&
                      itemIds.contains(i.itemId) &&
                      !i.status.isInProgress &&
                      !i.status.isDone),
            )
            .toList(),
      );

  Future<void> retryByItemId(String itemId, QueueItemKind kind) => _update(
    (current) => current
        .map(
          (i) => (i.itemId == itemId && i.itemType == kind)
              ? i.copyWith(
                  status: DeletionItemStatus.pending,
                  errorMessage: null,
                  processedAt: null,
                )
              : i,
        )
        .toList(),
  );

  /// Records the outcome of a My Activity script run on matching queue items.
  /// IDs that aren't in the queue are ignored.
  Future<void> recordMyActivityResults({
    required Set<String> deletedIds,
    required Map<String, String> errorsById,
  }) => _update((current) {
    final now = DateTime.now().toUtc();
    return current.map((i) {
      if (i.status.isDone) return i;
      if (deletedIds.contains(i.itemId)) {
        return i.copyWith(
          status: DeletionItemStatus.succeeded,
          errorMessage: null,
          processedAt: now,
        );
      }
      final error = errorsById[i.itemId];
      if (error != null) {
        return i.copyWith(
          status: DeletionItemStatus.failed,
          errorMessage: error,
          processedAt: now,
        );
      }
      return i;
    }).toList();
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Replaces the item [queueItemId] with [updated].
  Future<void> updateItem(String queueItemId, DeletionQueueItem updated) =>
      _update(
        (current) =>
            current.map((i) => i.id == queueItemId ? updated : i).toList(),
      );

  Future<void> _resetItemsByStatus(
    DeletionItemStatus status,
    String channelId,
  ) => _update(
    (current) => current
        .map(
          (i) => i.status == status && i.authorChannelId == channelId
              ? i.copyWith(
                  status: DeletionItemStatus.pending,
                  errorMessage: null,
                  processedAt: null,
                )
              : i,
        )
        .toList(),
  );

  /// Sets the status of [channelId]'s pending items to [newStatus].
  Future<void> markRemainingPending(
    DeletionItemStatus newStatus,
    String channelId,
  ) => _update(
    (current) => current
        .map(
          (i) =>
              i.status == DeletionItemStatus.pending &&
                  i.authorChannelId == channelId
              ? i.copyWith(status: newStatus)
              : i,
        )
        .toList(),
  );

  /// Applies [change] to the queue and saves the result, unless nothing
  /// changed. The queue is read once loading is done and changed without
  /// awaiting in between, so concurrent changes can't overwrite each other.
  Future<void> _update(
    List<DeletionQueueItem> Function(List<DeletionQueueItem> current) change,
  ) async {
    await future;
    final current = state.requireValue;
    final updated = change(current);
    if (listEquals(updated, current)) return;
    state = AsyncData(updated);
    await _repository.saveQueue(updated);
  }

  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Not `1 << 32`: on web, JS shifts are 32-bit, so that's 0 and throws.
    final randomPart = random.nextInt(0xFFFFFFFF);
    return '${timestamp.toRadixString(36)}-${randomPart.toRadixString(36)}';
  }
}
