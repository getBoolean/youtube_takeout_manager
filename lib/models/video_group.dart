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
