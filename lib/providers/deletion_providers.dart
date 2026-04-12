import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  void removeSelectedComments() {
    ref.read(takeoutProvider.notifier).removeComments(state);
    state = {};
  }

  void removeSelectedLiveChats() {
    ref.read(takeoutProvider.notifier).removeLiveChats(state);
    state = {};
  }
}
