import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

part 'deletion_selection_controller.g.dart';

/// Manages the set of IDs currently selected for deletion in the UI. Clears
/// when another channel is viewed, whose items these aren't.
@riverpod
class DeletionSet extends _$DeletionSet {
  @override
  Set<String> build() {
    ref.watch(viewedChannelIdProvider);
    return {};
  }

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

  void removeAll(Iterable<String> ids) {
    state = {...state}..removeAll(ids);
  }

  void clear() {
    state = {};
  }
}
