import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

/// In the order groups are listed.
enum GroupType { video, post, orphaned }

/// Items on one video or community post, or on neither.
class VideoGroup<T> {
  final GroupType groupType;

  /// The video the items are on, for a [GroupType.video] group.
  final String? videoId;

  /// The post the items are on, for a [GroupType.post] group.
  final String? postId;

  final List<T> items;

  const VideoGroup.video(String this.videoId, this.items)
    : groupType = GroupType.video,
      postId = null;

  const VideoGroup.post(String this.postId, this.items)
    : groupType = GroupType.post,
      videoId = null;

  /// Items on neither a video nor a post.
  const VideoGroup.other(this.items)
    : groupType = GroupType.orphaned,
      videoId = null,
      postId = null;

  const VideoGroup._(this.groupType, this.videoId, this.postId, this.items);

  /// Tells the group apart from the others in its list.
  Object get groupKey => (groupType, videoId ?? postId);

  /// The same group with only [items].
  VideoGroup<T> withItems(List<T> items) =>
      VideoGroup._(groupType, videoId, postId, items);

  /// What the group's header shows, and the search matches: [video]'s title
  /// when it's known.
  String title(Video? video) => switch (groupType) {
    GroupType.video => video?.title ?? 'Video: $videoId',
    GroupType.post => 'Community Post: $postId',
    GroupType.orphaned => 'Other',
  };
}

/// Groups [items] by the video or post they're on, keeping their order
/// within each group. Video groups come first, then posts, then items on
/// neither; groups of a type are ordered by their first item, newest first.
List<VideoGroup<T>> groupByVideo<T extends Interaction>(Iterable<T> items) {
  final groups = <(GroupType, String?), List<T>>{};
  for (final item in items) {
    final key = switch (item) {
      Interaction(:final videoId?) => (GroupType.video, videoId),
      Interaction(:final postId?) => (GroupType.post, postId),
      _ => (GroupType.orphaned, null),
    };
    groups.putIfAbsent(key, () => []).add(item);
  }

  return [
    for (final MapEntry(key: (type, id), :value) in groups.entries)
      switch (type) {
        GroupType.video => VideoGroup<T>.video(id!, value),
        GroupType.post => VideoGroup<T>.post(id!, value),
        GroupType.orphaned => VideoGroup<T>.other(value),
      },
  ]..sort((a, b) {
    final byType = a.groupType.index.compareTo(b.groupType.index);
    if (byType != 0) return byType;
    return b.items.first.createdAt.compareTo(a.items.first.createdAt);
  });
}
