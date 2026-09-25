import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

part 'deleted_ids_repository.g.dart';

@Riverpod(keepAlive: true)
DeletedIdsRepository deletedIdsRepository(Ref ref) =>
    DeletedIdsRepository(ref.watch(kvStorageServiceProvider));

const _deletedCommentIdsKey = 'deleted_comment_ids';
const _deletedLiveChatIdsKey = 'deleted_live_chat_ids';

/// Persists deleted comment and live chat IDs to local storage
/// so they survive app restarts.
class DeletedIdsRepository {
  final KvStorageService _kv;

  DeletedIdsRepository(this._kv);

  Future<Set<String>> loadDeletedCommentIds() async {
    return (await _kv.getStringList(_deletedCommentIdsKey) ?? []).toSet();
  }

  Future<Set<String>> loadDeletedLiveChatIds() async {
    return (await _kv.getStringList(_deletedLiveChatIdsKey) ?? []).toSet();
  }

  Future<void> saveDeletedCommentIds(Set<String> ids) =>
      _kv.setStringList(_deletedCommentIdsKey, ids.toList());

  Future<void> saveDeletedLiveChatIds(Set<String> ids) =>
      _kv.setStringList(_deletedLiveChatIdsKey, ids.toList());
}
