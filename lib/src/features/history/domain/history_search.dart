import 'dart:typed_data';

import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

import 'history_days.dart';
import 'loaded_history.dart';
import 'watched_channels.dart';

/// What the history is narrowed to: text to search for, the channel of the
/// watched videos, and whether only entries removed from YouTube's history
/// are shown.
typedef HistoryFilters = ({
  String query,
  HistoryChannel? channel,
  bool removedOnly,
});

/// Whether [filters] narrow nothing.
bool isUnfiltered(HistoryFilters filters) =>
    filters.query.isEmpty && filters.channel == null && !filters.removedOnly;

/// What's shown of [loaded] for some filters: the watched videos and
/// searches by day (as indices into its lists), and the channels.
typedef HistoryResults = ({
  LoadedHistory loaded,
  List<HistoryDay> watchDays,
  List<HistoryDay> searchDays,
  List<WatchedChannel> channels,
});

/// Everything in [loaded], worked out while it was loaded.
HistoryResults defaultResults(LoadedHistory loaded) => (
  loaded: loaded,
  watchDays: loaded.watchDays,
  searchDays: loaded.searchDays,
  channels: loaded.watchedChannels,
);

/// Narrows [loaded] to [filters]. Watched videos match the search by title
/// or channel name, searches by their text, and channels by name first,
/// then by the titles of videos watched from them (counting only those).
///
/// Works through at most [sliceSize] entries at a time, awaiting [pause]
/// between slices so no frame waits on it, and gives up with null when
/// [cancelled] says a newer search replaced it. Counts go in typed arrays,
/// so a search allocates little for the collector to pause frames over.
Future<HistoryResults?> searchHistory(
  LoadedHistory loaded,
  HistoryFilters filters, {
  int sliceSize = 3000,
  Future<void> Function()? pause,
  bool Function()? cancelled,
}) async {
  final query = foldForSearch(filters.query);
  final removedOnly = filters.removedOnly;
  final channelIndex = switch (filters.channel) {
    // A channel this history doesn't have matches nothing.
    final channel? => loaded.channelIndexByKey[channel.key] ?? -2,
    null => null,
  };
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
  final channels = loaded.watchedChannels;
  final watchIndices = <int>[];
  // Per channel: how many videos' titles match, and the newest's index.
  final titleMatches = Int32List(channels.length);
  final newestMatch = Int32List(channels.length);
  if (!await sliced(watches.length, (i) {
    final watch = watches[i];
    if ((!removedOnly || watch.removedAt != null) &&
        (channelIndex == null || channelOf[i] == channelIndex) &&
        watch.matches(query)) {
      watchIndices.add(i);
    }
    final c = channelOf[i];
    if (query.isNotEmpty && c >= 0 && watch.titleSearchText.contains(query)) {
      if (titleMatches[c]++ == 0) newestMatch[c] = i;
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

  List<WatchedChannel> found = channels;
  if (query.isNotEmpty) {
    final byName = <int>[];
    final byTitle = <int>[];
    if (!await sliced(channels.length, (c) {
      if (channels[c].searchText.contains(query)) {
        byName.add(c);
      } else if (titleMatches[c] > 0) {
        byTitle.add(c);
      }
    })) {
      return null;
    }
    // Channels are already the most watched first; among those found by
    // title, most matches first, ties as before.
    byTitle.sort((a, b) {
      final byCount = titleMatches[b] - titleMatches[a];
      return byCount != 0 ? byCount : a - b;
    });
    if (!await keepGoing()) return null;
    found = [for (final c in byName) channels[c]];
    if (!await sliced(byTitle.length, (i) {
      final c = byTitle[i];
      found.add(
        channels[c].found(
          count: titleMatches[c],
          lastWatched: watches[newestMatch[c]].time,
          byTitle: true,
        ),
      );
    })) {
      return null;
    }
  }

  final watchDays = groupByDay(watchIndices, loaded.watchDayKeys);
  if (!await keepGoing()) return null;
  return (
    loaded: loaded,
    watchDays: watchDays,
    searchDays: groupByDay(searchIndices, loaded.searchDayKeys),
    channels: found,
  );
}
