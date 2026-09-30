import 'dart:typed_data';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';

import 'channel_groups.dart';

/// The key of the group of channels not categorized.
const uncategorizedGroupKey = '#uncategorized';

/// A category's watched videos, as indices into the history's watched
/// videos, newest first: those of its channels shown.
class HistoryCategoryGroup {
  /// The category's label, [uncategorizedGroupKey], or [noChannelGroupKey].
  final String key;

  /// Null for the channels not categorized and the videos without a
  /// channel.
  final CategoryPath? path;
  final List<int> indices;

  /// How many of its channels are shown, counting ones subscribed to but
  /// never watched.
  final int channelCount;

  /// Of the videos shown that have a channel, from 0 to 1.
  final double share;

  const HistoryCategoryGroup({
    required this.key,
    required this.path,
    required this.indices,
    required this.channelCount,
    required this.share,
  });
}

/// The watched videos shown, grouped by category: the most watched first,
/// then the channels not categorized, then the videos without a channel.
class CategoryGroups {
  final List<HistoryCategoryGroup> groups;

  /// The channel groups these were made from.
  final ChannelGroups _channels;

  /// Which of [groups] has each of [_channels]' groups.
  final Int32List _groupOfChannelGroup;

  const CategoryGroups._(
    this.groups,
    this._channels,
    this._groupOfChannelGroup,
  );

  static final empty = CategoryGroups._(
    const [],
    ChannelGroups.empty,
    Int32List(0),
  );

  /// Which group has the watched video at [watchIndex], and where in it, or
  /// null when it isn't shown. [watchChannelIndex] gives each watched
  /// video's channel, as the loaded history has it.
  (int, int)? locate(int watchIndex, Int32List watchChannelIndex) {
    final (channelGroup, _) =
        _channels.locate(watchIndex, watchChannelIndex) ?? (-1, -1);
    if (channelGroup < 0) return null;
    final group = _groupOfChannelGroup[channelGroup];
    final position = sortedIndexOf(groups[group].indices, watchIndex);
    return position < 0 ? null : (group, position);
  }
}

/// Groups [channels]' videos by the category [categoryOf] gives each
/// channel's key (null when it has none).
CategoryGroups groupByCategory(
  ChannelGroups channels, {
  required CategoryPath? Function(String key) categoryOf,
}) {
  final keyOfChannelGroup = <String>[];
  final paths = <String, CategoryPath?>{};
  final parts = <String, List<List<int>>>{};
  final channelCounts = <String, int>{};
  final watchCounts = <String, int>{};
  var total = 0;
  for (final group in channels.groups) {
    final path = group.channel == null ? null : categoryOf(group.key);
    final key = group.channel == null
        ? noChannelGroupKey
        : path?.label ?? uncategorizedGroupKey;
    keyOfChannelGroup.add(key);
    paths[key] = path;
    parts.putIfAbsent(key, () => []).add(group.indices);
    watchCounts[key] = (watchCounts[key] ?? 0) + group.indices.length;
    if (group.channel != null) {
      channelCounts[key] = (channelCounts[key] ?? 0) + 1;
      total += group.indices.length;
    }
  }

  const last = {uncategorizedGroupKey, noChannelGroupKey};
  final order = [
    for (final key in parts.keys)
      if (!last.contains(key)) key,
  ];
  order.sort((a, b) {
    final byWatches = watchCounts[b]!.compareTo(watchCounts[a]!);
    if (byWatches != 0) return byWatches;
    final byChannels = channelCounts[b]!.compareTo(channelCounts[a]!);
    if (byChannels != 0) return byChannels;
    return a.compareTo(b);
  });
  for (final key in last) {
    if (parts.containsKey(key)) order.add(key);
  }

  final position = {for (final (i, key) in order.indexed) key: i};
  final groups = [
    for (final key in order)
      HistoryCategoryGroup(
        key: key,
        path: paths[key],
        indices: switch (parts[key]!) {
          [final only] => only,
          final several => [for (final part in several) ...part]..sort(),
        },
        channelCount: channelCounts[key] ?? 0,
        share: key == noChannelGroupKey || total == 0
            ? 0
            : watchCounts[key]! / total,
      ),
  ];
  return CategoryGroups._(
    groups,
    channels,
    Int32List.fromList([for (final key in keyOfChannelGroup) position[key]!]),
  );
}
