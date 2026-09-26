import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

part 'deleted_ids_repository.g.dart';

@Riverpod(keepAlive: true)
DeletedIdsRepository deletedIdsRepository(Ref ref) =>
    DeletedIdsRepository(ref.watch(kvStorageServiceProvider));

String _deletedIdsKey(QueueItemKind kind) => switch (kind) {
  QueueItemKind.comment => 'deleted_comment_ids',
  QueueItemKind.liveChat => 'deleted_live_chat_ids',
};

/// Persists deleted comment and live chat IDs to local storage
/// so they survive app restarts.
class DeletedIdsRepository {
  final KvStorageService _kv;

  DeletedIdsRepository(this._kv);

  Future<Set<String>> loadDeletedIds(QueueItemKind kind) async {
    return (await _kv.getStringList(_deletedIdsKey(kind)) ?? []).toSet();
  }

  Future<void> saveDeletedIds(QueueItemKind kind, Set<String> ids) =>
      _kv.setStringList(_deletedIdsKey(kind), ids.toList());
}
