import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/deletion_item_status.dart';
import '../models/queue_item_kind.dart';
import '../models/deletion_queue_item.dart';
import '../models/quota_operation.dart';
import '../services/deletion_queue_persistence_service.dart';
import '../services/google_auth_service.dart';
import '../services/youtube_deletion_service.dart';
import 'auth_providers.dart';
import 'deleted_ids_providers.dart';
import 'quota_provider.dart';

part 'deletion_queue_provider.g.dart';

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

  // ---------------------------------------------------------------------------
  // Enqueue
  // ---------------------------------------------------------------------------

  Future<void> enqueueComments(
    Set<String> ids, {
    Map<String, String?> snippets = const {},
  }) async {
    await _enqueue(ids, QueueItemKind.comment, snippets);
  }

  Future<void> enqueueLiveChats(
    Set<String> ids, {
    Map<String, String?> snippets = const {},
  }) async {
    await _enqueue(ids, QueueItemKind.liveChat, snippets);
  }

  Future<void> _enqueue(
    Set<String> ids,
    QueueItemKind type,
    Map<String, String?> snippets,
  ) async {
    final current = await future;
    final existingItemIds = current
        .where((i) => i.itemType == type)
        .map((i) => i.itemId)
        .toSet();
    final newIds = ids.difference(existingItemIds);
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

  Future<void> startProcessing() async {
    if (_isProcessing) return;
    _isPaused = false;
    await _processQueue();
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

  // ---------------------------------------------------------------------------
  // Processing loop
  // ---------------------------------------------------------------------------

  Future<void> _processQueue() async {
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
