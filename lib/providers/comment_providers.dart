import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/comment.dart';
import 'takeout_providers.dart';

part 'comment_providers.g.dart';

@riverpod
List<Comment> allComments(Ref ref) {
  return ref.watch(takeoutProvider)?.comments ?? [];
}

@riverpod
Map<String, List<Comment>> commentsByChannel(Ref ref) {
  final comments = ref.watch(allCommentsProvider);
  final grouped = <String, List<Comment>>{};
  for (final comment in comments) {
    grouped.putIfAbsent(comment.channelId, () => []).add(comment);
  }
  return grouped;
}

@riverpod
List<Comment> channelComments(Ref ref, String channelId) {
  final byChannel = ref.watch(commentsByChannelProvider);
  final comments = byChannel[channelId] ?? [];
  return comments..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
