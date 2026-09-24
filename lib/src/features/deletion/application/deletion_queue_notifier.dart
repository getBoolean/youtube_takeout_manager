import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_service.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import '../data/deletion_queue_persistence_service.dart';
import '../data/youtube_deletion_service.dart';
import '../domain/deletion_item_status.dart';
import '../domain/deletion_queue_item.dart';
import '../domain/deletion_targets.dart';
import '../domain/queue_item_kind.dart';
import 'deleted_ids_providers.dart';

part 'deletion_queue_notifier.g.dart';

@Riverpod(keepAlive: true)
class DeletionQueue extends _$DeletionQueue {
  static const _delayBetweenRequests = Duration(milliseconds: 100);

  final _persistence = DeletionQueuePersistenceService();
  final _deletionService = YoutubeDeletionService();
  bool _isProcessing = false;
  bool _isPaused = false;

  @override
  Future<List<DeletionQueueItem>> build() async {
    return _persistence.loadQueue();
  }

  bool get isProcessing => _isProcessing;
  bool get isPaused => _isPaused;

  /// Items still waiting to be deleted, including those stopped by the quota.
  List<DeletionQueueItem> get pendingItems => [
    for (final i in state.value ?? const <DeletionQueueItem>[])
      if (i.status == DeletionItemStatus.pending ||
          i.status == DeletionItemStatus.quotaExceeded)
        i,
  ];

  // ---------------------------------------------------------------------------
  // Enqueue
  // ---------------------------------------------------------------------------

  Future<void> enqueue(DeletionTargets targets) async {
    await _enqueue(QueueItemKind.comment, targets.commentSnippets);
    await _enqueue(QueueItemKind.liveChat, targets.liveChatSnippets);
  }

  Future<void> _enqueue(
    QueueItemKind type,
    Map<String, String?> snippets,
  ) async {
    final current = await future;
    final existingItemIds = current
        .where((i) => i.itemType == type)
        .map((i) => i.itemId)
        .toSet();
    final newIds = snippets.keys.toSet().difference(existingItemIds);
    if (newIds.isEmpty) return;

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
      );
    }).toList();

    final updated = [...current, ...newItems];
    state = AsyncData(updated);
    await _persistence.saveQueue(updated);
  }

  // ---------------------------------------------------------------------------
  // Processing control
  // ---------------------------------------------------------------------------

  Future<void> startYoutubeApiProcessing() async {
    if (_isProcessing) return;
    _isPaused = false;
    await _processQueueViaYoutubeApi();
  }

  /// Re-queues items stopped by the quota, then deletes every pending item
  /// via the YouTube API.
  Future<void> processPendingViaYoutubeApi() async {
    await retryQuotaExceeded();
    await startYoutubeApiProcessing();
  }

  void pauseProcessing() {
    _isPaused = true;
  }

  void cancelProcessing() {
    _isPaused = true;
    _isProcessing = false;
  }

  // ---------------------------------------------------------------------------
  // Item management
  // ---------------------------------------------------------------------------

  Future<void> retryFailed() async {
    await _resetItemsByStatus(DeletionItemStatus.failed);
  }

  Future<void> retryQuotaExceeded() async {
    await _resetItemsByStatus(DeletionItemStatus.quotaExceeded);
  }

  Future<void> clearCompleted() async {
    final current = await future;
    final updated = current
        .where((i) => i.status != DeletionItemStatus.succeeded)
        .toList();
    state = AsyncData(updated);
    await _persistence.saveQueue(updated);
  }

  Future<void> removeItem(String queueItemId) async {
    final current = await future;
    final updated = current.where((i) => i.id != queueItemId).toList();
    state = AsyncData(updated);
    await _persistence.saveQueue(updated);
  }

  Future<void> removeByItemId(String itemId, QueueItemKind kind) async {
    final current = await future;
    final updated = current
        .where((i) => !(i.itemId == itemId && i.itemType == kind))
        .toList();
    if (updated.length == current.length) return;
    state = AsyncData(updated);
    await _persistence.saveQueue(updated);
  }

  Future<void> retryByItemId(String itemId, QueueItemKind kind) async {
    final current = await future;
    final updated = current
        .map(
          (i) => (i.itemId == itemId && i.itemType == kind)
              ? i.copyWith(
                  status: DeletionItemStatus.pending,
                  errorMessage: null,
                  processedAt: null,
                )
              : i,
        )
        .toList();
    state = AsyncData(updated);
    await _persistence.saveQueue(updated);
  }

  /// Records the outcome of a My Activity script run on matching queue items.
  /// IDs that aren't in the queue are ignored.
  Future<void> recordMyActivityResults({
    required Set<String> deletedIds,
    required Map<String, String> errorsById,
  }) async {
    final current = await future;
    final now = DateTime.now().toUtc();
    var changed = false;
    final updated = current.map((i) {
      if (i.status == DeletionItemStatus.succeeded) return i;
      if (deletedIds.contains(i.itemId)) {
        changed = true;
        return i.copyWith(
          status: DeletionItemStatus.succeeded,
          errorMessage: null,
          processedAt: now,
        );
      }
      final error = errorsById[i.itemId];
      if (error != null) {
        changed = true;
        return i.copyWith(
          status: DeletionItemStatus.failed,
          errorMessage: error,
          processedAt: now,
        );
      }
      return i;
    }).toList();
    if (!changed) return;
    state = AsyncData(updated);
    await _persistence.saveQueue(updated);
  }

  // ---------------------------------------------------------------------------
  // Processing loop
  // ---------------------------------------------------------------------------

  Future<void> _processQueueViaYoutubeApi() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final authState = ref.read(authProvider);
    if (authState == null) {
      _isProcessing = false;
      return;
    }

    final client = GoogleAuthService.instance.getAuthenticatedClient(
      authState.accessToken,
    );

    try {
      await ref.read(quotaProvider.notifier).resetIfNewDay();

      while (!_isPaused) {
        final canDelete = await ref
            .read(quotaProvider.notifier)
            .canAfford(QuotaOperation.deleteComment.cost);
        if (!canDelete) {
          await _markRemainingPending(DeletionItemStatus.quotaExceeded);
          break;
        }

        final items = await future;
        final nextItem = items.cast<DeletionQueueItem?>().firstWhere(
          (i) => i!.status == DeletionItemStatus.pending,
          orElse: () => null,
        );
        if (nextItem == null) break;

        // Mark as in progress.
        await _updateItem(
          nextItem.id,
          nextItem.copyWith(status: DeletionItemStatus.inProgress),
        );

        // Call the YouTube API.
        final result = await _deletionService.deleteItem(
          client,
          nextItem.itemId,
        );

        final now = DateTime.now().toUtc();

        if (result.succeeded) {
          final op = nextItem.itemType == QueueItemKind.comment
              ? QuotaOperation.deleteComment
              : QuotaOperation.deleteLiveChat;
          await ref.read(quotaProvider.notifier).recordUsage(op);
          await _updateItem(
            nextItem.id,
            nextItem.copyWith(
              status: DeletionItemStatus.succeeded,
              processedAt: now,
            ),
          );

          // Persist as deleted and notify UI to re-render with deleted styling.
          final idSet = {nextItem.itemId};
          if (nextItem.itemType == QueueItemKind.comment) {
            await ref
                .read(deletedCommentIdsProvider.notifier)
                .markDeleted(idSet);
          } else {
            await ref
                .read(deletedLiveChatIdsProvider.notifier)
                .markDeleted(idSet);
          }
        } else if (result.quotaExceeded) {
          await _updateItem(
            nextItem.id,
            nextItem.copyWith(
              status: DeletionItemStatus.quotaExceeded,
              errorMessage: result.error,
              processedAt: now,
            ),
          );
          await _markRemainingPending(DeletionItemStatus.quotaExceeded);
          break;
        } else {
          await _updateItem(
            nextItem.id,
            nextItem.copyWith(
              status: DeletionItemStatus.failed,
              errorMessage: result.error,
              processedAt: now,
            ),
          );
        }

        await Future.delayed(_delayBetweenRequests);
      }
    } finally {
      client.close();
      _isProcessing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _updateItem(
    String queueItemId,
    DeletionQueueItem updated,
  ) async {
    final current = await future;
    final items = current
        .map((i) => i.id == queueItemId ? updated : i)
        .toList();
    state = AsyncData(items);
    await _persistence.saveQueue(items);
  }

  Future<void> _resetItemsByStatus(DeletionItemStatus status) async {
    final current = await future;
    final updated = current
        .map(
          (i) => i.status == status
              ? i.copyWith(
                  status: DeletionItemStatus.pending,
                  errorMessage: null,
                  processedAt: null,
                )
              : i,
        )
        .toList();
    state = AsyncData(updated);
    await _persistence.saveQueue(updated);
  }

  Future<void> _markRemainingPending(DeletionItemStatus newStatus) async {
    final current = await future;
    final updated = current
        .map(
          (i) => i.status == DeletionItemStatus.pending
              ? i.copyWith(status: newStatus)
              : i,
        )
        .toList();
    state = AsyncData(updated);
    await _persistence.saveQueue(updated);
  }

  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(1 << 32);
    return '${timestamp.toRadixString(36)}-${randomPart.toRadixString(36)}';
  }
}
