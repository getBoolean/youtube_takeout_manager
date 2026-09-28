import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../domain/history_days.dart';
import '../domain/loaded_history.dart';
import '../domain/watched_channels.dart';
import 'history_channel_filter.dart';
import 'history_removed_filter.dart';
import 'history_search_query.dart';
import 'takeout_history_notifier.dart';

part 'history_providers.g.dart';

/// The loaded history, or none while it loads.
@riverpod
LoadedHistory loadedHistory(Ref ref) =>
    ref.watch(takeoutHistoryProvider).value ?? LoadedHistory.empty;

/// The watched videos that match the search and filters, by day,
/// newest first. Entries are indices into the history's watched videos.
@riverpod
List<HistoryDay> watchDays(Ref ref) {
  final loaded = ref.watch(loadedHistoryProvider);
  final watches = loaded.history.watches;
  final query = foldForSearch(ref.watch(historySearchQueryProvider));
  final channel = ref.watch(historyChannelFilterProvider);
  final removedOnly = ref.watch(historyRemovedFilterProvider);
  return groupByDay([
    for (var i = 0; i < watches.length; i++)
      if ((!removedOnly || watches[i].removedAt != null) &&
          (channel?.matches(watches[i]) ?? true) &&
          watches[i].matches(query))
        i,
  ], loaded.watchDayKeys);
}

/// The searches that match the search and the Removed filter, by day,
/// newest first. Entries are indices into the history's searches.
@riverpod
List<HistoryDay> searchDays(Ref ref) {
  final loaded = ref.watch(loadedHistoryProvider);
  final searches = loaded.history.searches;
  final query = foldForSearch(ref.watch(historySearchQueryProvider));
  final removedOnly = ref.watch(historyRemovedFilterProvider);
  return groupByDay([
    for (var i = 0; i < searches.length; i++)
      if ((!removedOnly || searches[i].removedAt != null) &&
          searches[i].searchText.contains(query))
        i,
  ], loaded.searchDayKeys);
}

/// The channels videos were watched from, the most watched first. A search
/// finds channels by name first, then those with videos whose titles match,
/// counting only those.
@riverpod
List<WatchedChannel> filteredWatchedChannels(Ref ref) {
  final loaded = ref.watch(loadedHistoryProvider);
  final query = foldForSearch(ref.watch(historySearchQueryProvider));
  if (query.isEmpty) return loaded.watchedChannels;
  final byName = [
    for (final c in loaded.watchedChannels)
      if (c.searchText.contains(query)) c,
  ];
  final named = {for (final c in byName) c.channel.key};
  final byTitle = countWatchedChannels([
    for (final w in loaded.history.watches)
      if (w.titleSearchText.contains(query)) w,
  ], byTitle: true);
  return [
    ...byName,
    for (final c in byTitle)
      if (!named.contains(c.channel.key)) c,
  ];
}
