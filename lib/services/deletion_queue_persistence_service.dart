import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/deletion_queue_item.dart';
import '../models/deletion_item_status.dart';
import '../models/deletion_item_type.dart';

class DeletionQueuePersistenceService {
  static const _filename = 'deletion_queue.json';

  Future<File> _getFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_filename');
  }

  Future<List<DeletionQueueItem>> loadQueue() async {
    final file = await _getFile();
    if (!await file.exists()) return [];

    final json = await file.readAsString();
    if (json.isEmpty) return [];

    final list = jsonDecode(json) as List;
    return list
        .map((e) => DeletionQueueItemMapper.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveQueue(List<DeletionQueueItem> items) async {
    final file = await _getFile();
    final list = items.map((e) => e.toMap()).toList();
    await file.writeAsString(jsonEncode(list));
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
