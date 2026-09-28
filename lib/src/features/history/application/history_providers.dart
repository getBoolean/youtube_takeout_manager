import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/history_days.dart';
import '../domain/history_search.dart';
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

/// What the history screen narrows the history to.
@riverpod
HistoryFilters historyFilters(Ref ref) => (
  query: ref.watch(historySearchQueryProvider),
  channel: ref.watch(historyChannelFilterProvider),
  removedOnly: ref.watch(historyRemovedFilterProvider),
);

/// The history narrowed to the filters, worked out a slice at a time
/// between frames so the screen keeps moving; a newer search stops it.
@riverpod
Future<HistoryResults> historySearch(Ref ref) async {
  final loaded = ref.watch(loadedHistoryProvider);
  final filters = ref.watch(historyFiltersProvider);
  if (isUnfiltered(filters)) return defaultResults(loaded);
  final results = await searchHistory(
    loaded,
    filters,
    pause: () => Future<void>.delayed(Duration.zero),
    cancelled: () => !ref.mounted,
  );
  // Only null when replaced, and then nothing reads it.
  return results ?? defaultResults(loaded);
}

/// What's shown: everything when unfiltered, else the newest search's
/// results, the previous ones while a search is under way.
@riverpod
HistoryResults historyResults(Ref ref) {
  final loaded = ref.watch(loadedHistoryProvider);
  if (isUnfiltered(ref.watch(historyFiltersProvider))) {
    return defaultResults(loaded);
  }
  final results = ref.watch(historySearchProvider).value;
  // Results for a history since replaced would point at the wrong entries.
  return results != null && identical(results.loaded, loaded)
      ? results
      : defaultResults(loaded);
}

/// The watched videos shown, by day, newest first. Entries are indices into
/// the history's watched videos.
@riverpod
List<HistoryDay> watchDays(Ref ref) =>
    ref.watch(historyResultsProvider.select((r) => r.watchDays));

/// The searches shown, by day, newest first. Entries are indices into the
/// history's searches.
@riverpod
List<HistoryDay> searchDays(Ref ref) =>
    ref.watch(historyResultsProvider.select((r) => r.searchDays));

/// The channels shown, the most watched first; searching finds them by name
/// first, then by the titles of videos watched from them.
@riverpod
List<WatchedChannel> filteredWatchedChannels(Ref ref) =>
    ref.watch(historyResultsProvider.select((r) => r.channels));
