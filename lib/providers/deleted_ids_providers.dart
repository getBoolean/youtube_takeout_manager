import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/deletion_persistence_service.dart';

part 'deleted_ids_providers.g.dart';

@Riverpod(keepAlive: true)
class DeletedCommentIds extends _$DeletedCommentIds {
  final _service = DeletionPersistenceService();

  @override
  Future<Set<String>> build() async {
    return _service.loadDeletedCommentIds();
  }

  Future<void> markDeleted(Set<String> ids) async {
    await _service.addDeletedCommentIds(ids);
    final current = await future;
    state = AsyncData({...current, ...ids});
  }
}

@Riverpod(keepAlive: true)
class DeletedLiveChatIds extends _$DeletedLiveChatIds {
  final _service = DeletionPersistenceService();

  @override
  Future<Set<String>> build() async {
    return _service.loadDeletedLiveChatIds();
  }

  Future<void> markDeleted(Set<String> ids) async {
    await _service.addDeletedLiveChatIds(ids);
    final current = await future;
    state = AsyncData({...current, ...ids});
  }
}
