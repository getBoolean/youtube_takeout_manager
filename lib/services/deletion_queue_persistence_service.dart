import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/deletion_queue_item.dart';
import '../models/deletion_item_status.dart';
import '../models/deletion_item_type.dart';

class DeletionQueuePersistenceService {
  static const _key = 'deletion_queue';

  Future<List<DeletionQueueItem>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null || json.isEmpty) return [];

    final list = jsonDecode(json) as List;
    return list
        .map((e) => DeletionQueueItemMapper.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveQueue(List<DeletionQueueItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final list = items.map((e) => e.toMap()).toList();
    await prefs.setString(_key, jsonEncode(list));
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
