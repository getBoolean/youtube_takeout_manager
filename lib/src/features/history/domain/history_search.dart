import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

import 'channel_groups.dart';
import 'history_days.dart';
import 'loaded_history.dart';
import 'watch_filters.dart';

/// What the history is narrowed to: text to search for, whether only
/// entries removed from YouTube's history are shown, whether Shorts and
/// videos watched on YouTube Music are shown, and the channels of the
/// watched videos (null for every channel, and the videos without one).
/// [shortWatches] says which watched videos are Shorts; without it, those
/// watched through a Shorts link are.
typedef HistoryFilters = ({
  String query,
  bool removedOnly,
  ShowFilter shorts,
  WatchMask? shortWatches,
  ShowFilter music,
  ChannelMask? channels,
});

/// Whether [filters] narrow nothing.
bool isUnfiltered(HistoryFilters filters) =>
    filters.query.isEmpty &&
    !filters.removedOnly &&
    filters.shorts == ShowFilter.all &&
    filters.music == ShowFilter.all &&
    filters.channels == null;

/// What's shown of [loaded] for some filters: the watched videos and
/// searches by day (as indices into its lists), and the watched videos by
/// channel.
typedef HistoryResults = ({
  LoadedHistory loaded,
  List<HistoryDay> watchDays,
  List<HistoryDay> searchDays,
  ChannelGroups channelGroups,
});

/// Everything in [loaded], worked out while it was loaded.
HistoryResults defaultResults(LoadedHistory loaded) => (
  loaded: loaded,
  watchDays: loaded.watchDays,
  searchDays: loaded.searchDays,
  channelGroups: loaded.channelGroups,
);

/// Whether [flag] passes [filter]: shown with the rest, alone, or hidden.
bool _shows(ShowFilter filter, bool flag) => switch (filter) {
  ShowFilter.all => true,
  ShowFilter.only => flag,
  ShowFilter.hide => !flag,
};

/// Narrows [loaded] to [filters]. Watched videos match the search by title
/// or channel name, and searches by their text. Grouped by channel, the
/// channels whose names match come first.
///
/// Works through at most [sliceSize] entries at a time, awaiting [pause]
/// between slices so no frame waits on it, and gives up with null when
/// [cancelled] says a newer search replaced it.
Future<HistoryResults?> searchHistory(
  LoadedHistory loaded,
  HistoryFilters filters, {
  int sliceSize = 3000,
  Future<void> Function()? pause,
  bool Function()? cancelled,
}) async {
  final query = foldForSearch(filters.query);
  final (:removedOnly, :shorts, :shortWatches, :music, :channels) = (
    removedOnly: filters.removedOnly,
    shorts: filters.shorts,
    shortWatches: filters.shortWatches,
    music: filters.music,
    channels: filters.channels,
  );
  Future<bool> keepGoing() async {
    await pause?.call();
    return !(cancelled?.call() ?? false);
  }

  /// Runs [step] on each of `0..count - 1`, a slice at a time. False when
  /// cancelled.
  Future<bool> sliced(int count, void Function(int i) step) async {
    for (var start = 0; start < count; start += sliceSize) {
      final end = start + sliceSize < count ? start + sliceSize : count;
      for (var i = start; i < end; i++) {
        step(i);
      }
      if (!await keepGoing()) return false;
    }
    return true;
  }

  final watches = loaded.history.watches;
  final channelOf = loaded.watchChannelIndex;
  final watchIndices = <int>[];
  if (!await sliced(watches.length, (i) {
    final watch = watches[i];
    if ((!removedOnly || watch.removedAt != null) &&
        (channels == null || channels.allows(channelOf[i])) &&
        _shows(shorts, shortWatches?.allows(i) ?? watch.isShort) &&
        _shows(music, watch.music) &&
        watch.matches(query)) {
      watchIndices.add(i);
    }
  })) {
    return null;
  }

  final searches = loaded.history.searches;
  final searchIndices = <int>[];
  if (!await sliced(searches.length, (i) {
    final search = searches[i];
    if ((!removedOnly || search.removedAt != null) &&
        search.searchText.contains(query)) {
      searchIndices.add(i);
    }
  })) {
    return null;
  }

  final watchedChannels = loaded.watchedChannels;
  final nameMatches = <int>{};
  if (query.isNotEmpty &&
      !await sliced(watchedChannels.length, (c) {
        if (watchedChannels[c].searchText.contains(query)) nameMatches.add(c);
      })) {
    return null;
  }

  final watchDays = groupByDay(watchIndices, loaded.watchDayKeys);
  if (!await keepGoing()) return null;
  final channelGroups = groupByChannel(
    channels: watchedChannels,
    watchChannelIndex: channelOf,
    watchIndices: watchIndices,
    nameMatches: nameMatches,
  );
  if (!await keepGoing()) return null;
  return (
    loaded: loaded,
    watchDays: watchDays,
    searchDays: groupByDay(searchIndices, loaded.searchDayKeys),
    channelGroups: channelGroups,
  );
}
