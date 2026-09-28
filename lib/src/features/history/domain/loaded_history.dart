import 'history_days.dart';
import 'takeout_history.dart';
import 'watched_channels.dart';

/// A takeout's history with what showing it needs worked out once, while
/// it's loaded: each entry's local day and the channels watched from.
/// Working these out for tens of thousands of entries takes long enough to
/// freeze the screen that first shows them.
class LoadedHistory {
  final TakeoutHistory history;

  /// The local day of each watched video and each search (see [dayKeyOf]).
  final List<int> watchDayKeys;
  final List<int> searchDayKeys;

  /// Every channel videos were watched from, the most watched first.
  final List<WatchedChannel> watchedChannels;

  /// How many watched videos and searches were removed from YouTube's
  /// history.
  final int removedWatchCount;
  final int removedSearchCount;

  const LoadedHistory._({
    required this.history,
    required this.watchDayKeys,
    required this.searchDayKeys,
    required this.watchedChannels,
    required this.removedWatchCount,
    required this.removedSearchCount,
  });

  factory LoadedHistory.of(TakeoutHistory history) => LoadedHistory._(
    history: history,
    watchDayKeys: [for (final w in history.watches) dayKeyOf(w.time)],
    searchDayKeys: [for (final s in history.searches) dayKeyOf(s.time)],
    watchedChannels: countWatchedChannels(history.watches),
    removedWatchCount: history.watches.where((w) => w.removedAt != null).length,
    removedSearchCount: history.searches
        .where((s) => s.removedAt != null)
        .length,
  );

  static const empty = LoadedHistory._(
    history: TakeoutHistory.empty,
    watchDayKeys: [],
    searchDayKeys: [],
    watchedChannels: [],
    removedWatchCount: 0,
    removedSearchCount: 0,
  );
}
