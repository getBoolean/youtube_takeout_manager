import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../domain/history_days.dart';
import '../domain/takeout_history.dart';
import '../domain/watched_channels.dart';
import 'history_channel_filter.dart';
import 'history_search_query.dart';
import 'takeout_history_notifier.dart';

part 'history_providers.g.dart';

/// The loaded history, or none while it loads.
@riverpod
TakeoutHistory loadedHistory(Ref ref) =>
    ref.watch(takeoutHistoryProvider).value ?? TakeoutHistory.empty;

/// The local day of each watch, worked out once per history.
@riverpod
List<int> watchDayKeys(Ref ref) => [
  for (final w in ref.watch(loadedHistoryProvider).watches) dayKeyOf(w.time),
];

/// The local day of each search, worked out once per history.
@riverpod
List<int> searchDayKeys(Ref ref) => [
  for (final s in ref.watch(loadedHistoryProvider).searches) dayKeyOf(s.time),
];

/// The watches that match the search and channel filter, by day, newest
/// first. Entries are indices into the history's watches.
@riverpod
List<HistoryDay> watchDays(Ref ref) {
  final watches = ref.watch(loadedHistoryProvider).watches;
  final query = foldForSearch(ref.watch(historySearchQueryProvider));
  final channel = ref.watch(historyChannelFilterProvider);
  return groupByDay([
    for (var i = 0; i < watches.length; i++)
      if ((channel?.matches(watches[i]) ?? true) &&
          watches[i].searchText.contains(query))
        i,
  ], ref.watch(watchDayKeysProvider));
}

/// The searches that match the search, by day, newest first. Entries are
/// indices into the history's searches.
@riverpod
List<HistoryDay> searchDays(Ref ref) {
  final searches = ref.watch(loadedHistoryProvider).searches;
  final query = foldForSearch(ref.watch(historySearchQueryProvider));
  return groupByDay([
    for (var i = 0; i < searches.length; i++)
      if (searches[i].searchText.contains(query)) i,
  ], ref.watch(searchDayKeysProvider));
}

/// Every channel videos were watched from, the most watched first.
@riverpod
List<WatchedChannel> watchedChannels(Ref ref) =>
    countWatchedChannels(ref.watch(loadedHistoryProvider).watches);

/// The [watchedChannelsProvider] whose names match the search.
@riverpod
List<WatchedChannel> filteredWatchedChannels(Ref ref) {
  final channels = ref.watch(watchedChannelsProvider);
  final query = foldForSearch(ref.watch(historySearchQueryProvider));
  if (query.isEmpty) return channels;
  return [
    for (final c in channels)
      if (c.searchText.contains(query)) c,
  ];
}
