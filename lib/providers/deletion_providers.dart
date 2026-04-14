import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/comment.dart';
import '../models/live_chat.dart';

part 'deletion_providers.g.dart';

/// Manages the set of IDs currently selected for deletion in the UI.
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

  void removeAll(Iterable<String> ids) {
    state = {...state}..removeAll(ids);
  }

  void clear() {
    state = {};
  }
}

/// Splits the current selection into just the comment IDs present in
/// the given channel's comments.
@riverpod
Set<String> selectedCommentIds(Ref ref, List<Comment> channelComments) {
  final selected = ref.watch(deletionSetProvider);
  final commentIdSet = channelComments.map((c) => c.commentId).toSet();
  return selected.intersection(commentIdSet);
}

/// Splits the current selection into just the live chat IDs present in
/// the given channel's live chats.
@riverpod
Set<String> selectedLiveChatIds(Ref ref, List<LiveChat> channelLiveChats) {
  final selected = ref.watch(deletionSetProvider);
  final chatIdSet = channelLiveChats.map((c) => c.liveChatId).toSet();
  return selected.intersection(chatIdSet);
}
