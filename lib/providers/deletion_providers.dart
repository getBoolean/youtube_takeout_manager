import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/deletion_persistence_service.dart';
import 'takeout_providers.dart';

part 'deletion_providers.g.dart';

@riverpod
class DeletionSet extends _$DeletionSet {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  void addAll(Iterable<String> ids) {
    state = {...state, ...ids};
  }

  void clear() {
    state = {};
  }

  Future<void> removeSelectedComments() async {
    final ids = state;
    ref.read(takeoutProvider.notifier).removeComments(ids);
    await DeletionPersistenceService().addDeletedCommentIds(ids);
    state = {};
  }

  Future<void> removeSelectedLiveChats() async {
    final ids = state;
    ref.read(takeoutProvider.notifier).removeLiveChats(ids);
    await DeletionPersistenceService().addDeletedLiveChatIds(ids);
    state = {};
  }
}
