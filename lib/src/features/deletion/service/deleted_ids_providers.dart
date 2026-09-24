import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/deleted_ids_repository.dart';
import '../model/deletion_item_status.dart';
import '../model/deletion_queue_item.dart';
import '../model/queue_item_kind.dart';
import 'deletion_queue_notifier.dart';

part 'deleted_ids_providers.g.dart';

@Riverpod(keepAlive: true)
class DeletedCommentIds extends _$DeletedCommentIds {
  DeletedIdsRepository get _repository =>
      ref.read(deletedIdsRepositoryProvider);

  @override
  Future<Set<String>> build() async {
    return ref.watch(deletedIdsRepositoryProvider).loadDeletedCommentIds();
  }

  Future<void> markDeleted(Set<String> ids) async {
    await _repository.addDeletedCommentIds(ids);
    final current = await future;
    state = AsyncData({...current, ...ids});
  }
}

@Riverpod(keepAlive: true)
class DeletedLiveChatIds extends _$DeletedLiveChatIds {
  DeletedIdsRepository get _repository =>
      ref.read(deletedIdsRepositoryProvider);

  @override
  Future<Set<String>> build() async {
    return ref.watch(deletedIdsRepositoryProvider).loadDeletedLiveChatIds();
  }

  Future<void> markDeleted(Set<String> ids) async {
    await _repository.addDeletedLiveChatIds(ids);
    final current = await future;
    state = AsyncData({...current, ...ids});
  }
}

bool _isActive(DeletionItemStatus s) =>
    s == DeletionItemStatus.pending || s == DeletionItemStatus.inProgress;

bool _isFailed(DeletionItemStatus s) =>
    s == DeletionItemStatus.failed || s == DeletionItemStatus.quotaExceeded;

Set<String> _filterQueueIds(
  List<DeletionQueueItem> items,
  QueueItemKind kind,
  bool Function(DeletionItemStatus) statusFilter,
) => {
  for (final i in items)
    if (i.itemType == kind && statusFilter(i.status)) i.itemId,
};

@riverpod
Set<String> queuedCommentIds(Ref ref) {
  final items = ref.watch(deletionQueueProvider).value ?? const [];
  return _filterQueueIds(items, QueueItemKind.comment, _isActive);
}

@riverpod
Set<String> queuedLiveChatIds(Ref ref) {
  final items = ref.watch(deletionQueueProvider).value ?? const [];
  return _filterQueueIds(items, QueueItemKind.liveChat, _isActive);
}

@riverpod
Set<String> failedCommentIds(Ref ref) {
  final items = ref.watch(deletionQueueProvider).value ?? const [];
  return _filterQueueIds(items, QueueItemKind.comment, _isFailed);
}

@riverpod
Set<String> failedLiveChatIds(Ref ref) {
  final items = ref.watch(deletionQueueProvider).value ?? const [];
  return _filterQueueIds(items, QueueItemKind.liveChat, _isFailed);
}
