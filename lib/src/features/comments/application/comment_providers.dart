import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import '../domain/comment.dart';

part 'comment_providers.g.dart';

@riverpod
List<Comment> allComments(Ref ref) {
  return ref.watch(viewedTakeoutProvider).value?.comments ?? [];
}

/// Comments by the channel their video is on. Comments whose video's channel
/// isn't known are kept under [unknownChannelId].
@Riverpod(keepAlive: true)
Map<String, List<Comment>> commentsByChannel(Ref ref) {
  final comments = ref.watch(allCommentsProvider);
  final videoMetadata = ref.watch(videoMetadataProvider).value ?? {};
  final grouped = <String, List<Comment>>{};
  for (final comment in comments) {
    final video = comment.videoId != null
        ? videoMetadata[comment.videoId]
        : null;
    grouped
        .putIfAbsent(video?.channelId ?? unknownChannelId, () => [])
        .add(comment);
  }
  return grouped;
}

@riverpod
List<Comment> channelComments(Ref ref, String channelId) {
  final byChannel = ref.watch(commentsByChannelProvider);
  final comments = byChannel[channelId] ?? const [];
  return [...comments]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
