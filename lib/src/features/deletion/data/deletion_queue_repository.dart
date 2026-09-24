import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/deletion_item_status.dart';
import '../domain/deletion_queue_item.dart';
import '../domain/queue_item_kind.dart';

part 'deletion_queue_repository.g.dart';

@Riverpod(keepAlive: true)
DeletionQueueRepository deletionQueueRepository(Ref ref) =>
    DeletionQueueRepository(ref.watch(kvStorageServiceProvider));

class DeletionQueueRepository {
  static const _key = 'deletion_queue';

  final KvStorageService _kv;

  DeletionQueueRepository(this._kv);

  Future<List<DeletionQueueItem>> loadQueue() async {
    final json = await _kv.getString(_key);
    if (json == null || json.isEmpty) return [];

    final list = jsonDecode(json) as List;
    return list
        .map((e) => DeletionQueueItemMapper.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveQueue(List<DeletionQueueItem> items) async {
    final list = items.map((e) => e.toMap()).toList();
    await _kv.setString(_key, jsonEncode(list));
  }

  /// Returns the set of successfully deleted comment and live chat IDs.
  Future<({Set<String> commentIds, Set<String> liveChatIds})>
  loadSucceededIds() async {
    final items = await loadQueue();
    final succeeded = items.where(
      (i) => i.status == DeletionItemStatus.succeeded,
    );

    final commentIds = succeeded
        .where((i) => i.itemType == QueueItemKind.comment)
        .map((i) => i.itemId)
        .toSet();
    final liveChatIds = succeeded
        .where((i) => i.itemType == QueueItemKind.liveChat)
        .map((i) => i.itemId)
        .toSet();

    return (commentIds: commentIds, liveChatIds: liveChatIds);
  }
}
