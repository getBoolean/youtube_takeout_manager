import 'dart:convert';

import '../models/deletion_queue_item.dart';
import '../models/deletion_item_status.dart';
import '../models/deletion_item_type.dart';
import 'kv_storage_service.dart';

class DeletionQueuePersistenceService {
  static const _key = 'deletion_queue';

  final _kv = KvStorageService();

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
    final succeeded =
        items.where((i) => i.status == DeletionItemStatus.succeeded);

    final commentIds = succeeded
        .where((i) => i.itemType == DeletionItemType.comment)
        .map((i) => i.itemId)
        .toSet();
    final liveChatIds = succeeded
        .where((i) => i.itemType == DeletionItemType.liveChat)
        .map((i) => i.itemId)
        .toSet();

    return (commentIds: commentIds, liveChatIds: liveChatIds);
  }
}
