import 'dart:typed_data';

import 'watched_channels.dart';

/// The key of the group of watched videos without a channel, such as ones
/// removed before the export.
const noChannelGroupKey = '#no-channel';

/// A channel's watched videos, as indices into the history's watched
/// videos, newest first. Empty for a channel subscribed to but never watched.
class HistoryChannelGroup {
  /// The channel's [HistoryChannel.key], or [noChannelGroupKey].
  final String key;

  /// Null for the videos without a channel.
  final HistoryChannel? channel;
  final List<int> indices;

  const HistoryChannelGroup({
    required this.key,
    required this.channel,
    required this.indices,
  });
}

/// The watched videos shown, grouped by channel: the channels named for a
/// search first, then the most watched, ties by name; channels subscribed to
/// but never watched after those; the videos without a channel last.
class ChannelGroups {
  final List<HistoryChannelGroup> groups;

  /// Where each channel of the history's watched channels is in [groups],
  /// or -1 when it isn't shown.
  final Int32List _groupOfChannel;

  /// Where the videos without a channel are in [groups], or -1.
  final int _noChannelGroup;

  const ChannelGroups._(
    this.groups,
    this._groupOfChannel,
    this._noChannelGroup,
  );

  static final empty = ChannelGroups._(const [], Int32List(0), -1);

  /// Which group has the watched video at [watchIndex], and where in it, or
  /// null when it isn't shown. [watchChannelIndex] gives each watched
  /// video's channel, as the loaded history has it.
  (int, int)? locate(int watchIndex, Int32List watchChannelIndex) {
    final channel = watchChannelIndex[watchIndex];
    final group = channel < 0
        ? _noChannelGroup
        : channel < _groupOfChannel.length
        ? _groupOfChannel[channel]
        : -1;
    if (group < 0) return null;
    final position = sortedIndexOf(groups[group].indices, watchIndex);
    return position < 0 ? null : (group, position);
  }

  /// These groups with [unwatched] channels added as empty groups, in the
  /// order given, before the videos without a channel.
  ChannelGroups withUnwatched(List<HistoryChannel> unwatched) {
    if (unwatched.isEmpty) return this;
    final noChannel = _noChannelGroup < 0 ? null : groups[_noChannelGroup];
    final watched = noChannel == null
        ? groups
        : groups.sublist(0, _noChannelGroup);
    return ChannelGroups._(
      [
        ...watched,
        for (final channel in unwatched)
          HistoryChannelGroup(
            key: channel.key,
            channel: channel,
            indices: const [],
          ),
        ?noChannel,
      ],
      _groupOfChannel,
      noChannel == null ? -1 : watched.length + unwatched.length,
    );
  }
}

/// Where [value] is in [sorted], ascending, or -1.
int sortedIndexOf(List<int> sorted, int value) {
  var low = 0;
  var high = sorted.length - 1;
  while (low <= high) {
    final mid = (low + high) >> 1;
    final at = sorted[mid];
    if (at == value) return mid;
    if (at < value) {
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }
  return -1;
}

/// Groups the watched videos at [watchIndices] (ascending, so newest first)
/// by channel. [channels] and [watchChannelIndex] are the loaded history's;
/// [nameMatches] are the channels whose names a search matched, listed
/// first.
ChannelGroups groupByChannel({
  required List<WatchedChannel> channels,
  required Int32List watchChannelIndex,
  required Iterable<int> watchIndices,
  Set<int> nameMatches = const {},
}) {
  final counts = Int32List(channels.length);
  var noChannel = 0;
  for (final i in watchIndices) {
    final c = watchChannelIndex[i];
    if (c < 0) {
      noChannel++;
    } else {
      counts[c]++;
    }
  }

  final shown = [
    for (var c = 0; c < channels.length; c++)
      if (counts[c] > 0) c,
  ];
  shown.sort((a, b) {
    final byName = (nameMatches.contains(a) ? 0 : 1).compareTo(
      nameMatches.contains(b) ? 0 : 1,
    );
    if (byName != 0) return byName;
    final byCount = counts[b].compareTo(counts[a]);
    if (byCount != 0) return byCount;
    return channels[a].channel.title.compareTo(channels[b].channel.title);
  });

  final groupOfChannel = Int32List(channels.length)
    ..fillRange(0, channels.length, -1);
  final lists = <List<int>>[];
  final groups = <HistoryChannelGroup>[];
  for (final c in shown) {
    groupOfChannel[c] = groups.length;
    final indices = <int>[];
    lists.add(indices);
    groups.add(
      HistoryChannelGroup(
        key: channels[c].channel.key,
        channel: channels[c].channel,
        indices: indices,
      ),
    );
  }
  final noChannelIndices = <int>[];
  for (final i in watchIndices) {
    final c = watchChannelIndex[i];
    if (c < 0) {
      noChannelIndices.add(i);
    } else {
      lists[groupOfChannel[c]].add(i);
    }
  }
  final noChannelGroup = noChannel == 0 ? -1 : groups.length;
  if (noChannel > 0) {
    groups.add(
      HistoryChannelGroup(
        key: noChannelGroupKey,
        channel: null,
        indices: noChannelIndices,
      ),
    );
  }
  return ChannelGroups._(groups, groupOfChannel, noChannelGroup);
}
