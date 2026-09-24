import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import '../domain/comment.dart';

part 'comment_providers.g.dart';

@riverpod
List<Comment> allComments(Ref ref) {
  return ref.watch(takeoutProvider).value?.comments ?? [];
}

@Riverpod(keepAlive: true)
Map<String, List<Comment>> commentsByChannel(Ref ref) {
  final comments = ref.watch(allCommentsProvider);
  final videoMetadata = ref.watch(videoMetadataProvider).value ?? {};
  final grouped = <String, List<Comment>>{};
  for (final comment in comments) {
    final video = comment.videoId != null
        ? videoMetadata[comment.videoId]
        : null;
    if (video == null) continue;
    grouped.putIfAbsent(video.channelId, () => []).add(comment);
  }
  return grouped;
}

@riverpod
List<Comment> channelComments(Ref ref, String channelId) {
  final byChannel = ref.watch(commentsByChannelProvider);
  final comments = byChannel[channelId] ?? [];
  return comments..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

@riverpod
class CommentSearchQuery extends _$CommentSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}
