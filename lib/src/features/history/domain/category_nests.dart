import 'dart:collection';
import 'dart:typed_data';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';
import 'channel_groups.dart';

/// A category's channels, as the watched videos show grouped by channel
/// with categories picked: [videoCount] of the videos shown, their [share]
/// of them from 0 to 1, and the channels in the Channel grouping's order.
class CategoryNest {
  /// Its row's label: one nest per row.
  final String key;
  final CategoryPick pick;
  final List<HistoryChannelGroup> channels;
  final int videoCount;
  final double share;

  const CategoryNest({
    required this.key,
    required this.pick,
    required this.channels,
    required this.videoCount,
    required this.share,
  });

  int get channelCount => channels.length;
}

/// [groups], already in the Channel grouping's order, under the rows of
/// the category filter [picks] their channels' categories match: the most
/// specific one, else, for a channel shown for another reason, its own
/// category's row. The most watched first, the uncategorized last; the
/// videos without a channel are left out. Takes each group as it is,
/// reading no video list: O(channels).
List<CategoryNest> nestByCategory(
  Iterable<HistoryChannelGroup> groups, {
  required Set<CategoryPick> picks,
  required CategoryPath? Function(String key) categoryOf,
}) {
  final channels = <CategoryPick, List<HistoryChannelGroup>>{};
  final videos = <CategoryPick, int>{};
  var total = 0;
  for (final group in groups) {
    if (group.channel == null) continue;
    final pick = _rowOf(categoryOf(group.key), picks);
    (channels[pick] ??= []).add(group);
    videos[pick] = (videos[pick] ?? 0) + group.indices.length;
    total += group.indices.length;
  }
  return [
    for (final MapEntry(key: pick, value: nested) in channels.entries)
      CategoryNest(
        key: pick.label,
        pick: pick,
        channels: nested,
        videoCount: videos[pick]!,
        share: total == 0 ? 0 : videos[pick]! / total,
      ),
  ]..sort((a, b) {
    final uncategorized = (a.pick.parent == null ? 1 : 0).compareTo(
      b.pick.parent == null ? 1 : 0,
    );
    if (uncategorized != 0) return uncategorized;
    final watched = b.videoCount.compareTo(a.videoCount);
    return watched != 0 ? watched : a.key.compareTo(b.key);
  });
}

/// The row a channel in [path] nests under: the most specific of [picks]
/// it matches, else its category's.
CategoryPick _rowOf(CategoryPath? path, Set<CategoryPick> picks) {
  CategoryPick? whole;
  for (final pick in picks) {
    if (!pick.matches(path)) continue;
    if (!pick.isCategory) return pick;
    whole = pick;
  }
  return whole ??
      (path == null
          ? const CategoryPick.uncategorized()
          : CategoryPick.category(path.parent));
}

/// A row of a nest: a channel's header, or one of its watched videos.
sealed class NestedRow {
  const NestedRow();
}

final class ChannelRow extends NestedRow {
  final HistoryChannelGroup group;

  const ChannelRow(this.group);
}

final class VideoRow extends NestedRow {
  /// Its index in the history's watched videos.
  final int watchIndex;

  const VideoRow(this.watchIndex);
}

/// A nest's rows: each of its [channels], followed by its videos while
/// [isOpen] says so. Made on access from where each channel starts, so
/// building them is O(channels) and reads no video list.
class NestedRows extends ListBase<NestedRow> {
  final List<HistoryChannelGroup> _channels;

  /// The row each channel starts at, then how many rows there are.
  final Int32List _starts;

  NestedRows._(this._channels, this._starts);

  factory NestedRows(
    List<HistoryChannelGroup> channels,
    bool Function(String key) isOpen,
  ) {
    final starts = Int32List(channels.length + 1);
    var row = 0;
    for (var c = 0; c < channels.length; c++) {
      starts[c] = row;
      final group = channels[c];
      row += 1 + (isOpen(group.key) ? group.indices.length : 0);
    }
    starts[channels.length] = row;
    return NestedRows._(channels, starts);
  }

  @override
  int get length => _starts.last;

  @override
  set length(int _) => throw UnsupportedError('A nest has the rows it has.');

  @override
  NestedRow operator [](int index) {
    RangeError.checkValidIndex(index, this);
    // The last channel starting at or before [index].
    var low = 0;
    var high = _channels.length - 1;
    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (_starts[middle] <= index) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    final group = _channels[low];
    final offset = index - _starts[low];
    return offset == 0
        ? ChannelRow(group)
        : VideoRow(group.indices[offset - 1]);
  }

  @override
  void operator []=(int index, NestedRow value) =>
      throw UnsupportedError('A nest has the rows it has.');
}
