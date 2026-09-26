import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/deletion_queue_item.dart';

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
}
