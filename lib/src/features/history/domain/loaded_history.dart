import 'dart:typed_data';

import 'history_days.dart';
import 'takeout_history.dart';
import 'watched_channels.dart';

/// A takeout's history with what showing it needs worked out once, while
/// it's loaded: each entry's local day, the unfiltered lists by day, and the
/// channels watched from. Working these out for tens of thousands of
/// entries takes far longer than a frame.
class LoadedHistory {
  final TakeoutHistory history;

  /// The local day of each watched video and each search (see [dayKeyOf]).
  final List<int> watchDayKeys;
  final List<int> searchDayKeys;

  /// Every watched video and search by day, newest first.
  final List<HistoryDay> watchDays;
  final List<HistoryDay> searchDays;

  /// Every channel videos were watched from, the most watched first.
  final List<WatchedChannel> watchedChannels;

  /// The ID of every channel videos were watched from, the most recently
  /// watched first: the order the watched videos are listed in.
  final List<String> recentChannelIds;

  /// Where each channel is in [watchedChannels], by [HistoryChannel.key].
  final Map<Object, int> channelIndexByKey;

  /// Where each watched video's channel is in [watchedChannels], or -1 when
  /// it has none: searches compare these instead of channels.
  final Int32List watchChannelIndex;

  /// How many watched videos and searches were removed from YouTube's
  /// history.
  final int removedWatchCount;
  final int removedSearchCount;

  LoadedHistory._({
    required this.history,
    required this.watchDayKeys,
    required this.searchDayKeys,
    required this.watchDays,
    required this.searchDays,
    required this.watchedChannels,
    required this.recentChannelIds,
    required this.channelIndexByKey,
    required this.watchChannelIndex,
    required this.removedWatchCount,
    required this.removedSearchCount,
  });

  factory LoadedHistory.of(TakeoutHistory history) {
    final watchDayKeys = [for (final w in history.watches) dayKeyOf(w.time)];
    final searchDayKeys = [for (final s in history.searches) dayKeyOf(s.time)];
    final channels = countWatchedChannels(history.watches);
    final channelIndexByKey = {
      for (final (i, c) in channels.indexed) c.channel.key: i,
    };
    final watchChannelIndex = Int32List(history.watches.length);
    for (final (i, watch) in history.watches.indexed) {
      final key = HistoryChannel.of(watch)?.key;
      watchChannelIndex[i] = key == null ? -1 : channelIndexByKey[key]!;
    }
    return LoadedHistory._(
      history: history,
      watchDayKeys: watchDayKeys,
      searchDayKeys: searchDayKeys,
      watchDays: groupByDay([
        for (var i = 0; i < watchDayKeys.length; i++) i,
      ], watchDayKeys),
      searchDays: groupByDay([
        for (var i = 0; i < searchDayKeys.length; i++) i,
      ], searchDayKeys),
      watchedChannels: channels,
      // The watches are newest first.
      recentChannelIds: {
        for (final watch in history.watches) ?watch.channelId,
      }.toList(),
      channelIndexByKey: channelIndexByKey,
      watchChannelIndex: watchChannelIndex,
      removedWatchCount: history.watches
          .where((w) => w.removedAt != null)
          .length,
      removedSearchCount: history.searches
          .where((s) => s.removedAt != null)
          .length,
    );
  }

  static final empty = LoadedHistory.of(TakeoutHistory.empty);
}
