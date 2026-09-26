import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';

/// In the order groups are listed.
enum GroupType { video, post, orphaned }

class VideoGroup<T> {
  final String groupKey;
  final GroupType groupType;
  final List<T> items;

  const VideoGroup({
    required this.groupKey,
    required this.groupType,
    required this.items,
  });
}

const _orphanedKey = '_orphaned';

/// Groups [items] by the video or post they're on, keeping their order
/// within each group. Video groups come first, then posts, then items on
/// neither; groups of a type are ordered by their first item, newest first.
List<VideoGroup<T>> groupByVideo<T extends Interaction>(Iterable<T> items) {
  final groups = <String, List<T>>{};
  for (final item in items) {
    final key = switch (item) {
      Interaction(:final videoId?) => videoId,
      Comment(:final postId?) => 'post:$postId',
      _ => _orphanedKey,
    };
    groups.putIfAbsent(key, () => []).add(item);
  }

  return [
    for (final MapEntry(:key, :value) in groups.entries)
      VideoGroup<T>(
        groupKey: key,
        groupType: key == _orphanedKey
            ? GroupType.orphaned
            : key.startsWith('post:')
            ? GroupType.post
            : GroupType.video,
        items: value,
      ),
  ]..sort((a, b) {
    final byType = a.groupType.index.compareTo(b.groupType.index);
    if (byType != 0) return byType;
    return b.items.first.createdAt.compareTo(a.items.first.createdAt);
  });
}
