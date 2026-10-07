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

/// How many videos were watched from each of [loaded]'s watched channels,
/// in its order, of the kinds [shorts] and [music] show; [shortWatches]
/// says which are Shorts, as for [HistoryFilters].
List<int> countChannelWatches(
  LoadedHistory loaded, {
  ShowFilter shorts = ShowFilter.all,
  WatchMask? shortWatches,
  ShowFilter music = ShowFilter.all,
}) {
  if (shorts == ShowFilter.all && music == ShowFilter.all) {
    return [for (final watched in loaded.watchedChannels) watched.count];
  }
  final counts = List.filled(loaded.watchedChannels.length, 0);
  for (final (i, watch) in loaded.history.watches.indexed) {
    final channel = loaded.watchChannelIndex[i];
    if (channel >= 0 &&
        _shows(shorts, shortWatches?.allows(i) ?? watch.isShort) &&
        _shows(music, watch.music)) {
      counts[channel]++;
    }
  }
  return counts;
}

/// Narrows [loaded] to [filters]. Watched videos match the search by title
/// or channel name, and searches by their text. Grouped by channel, the
/// channels whose names match come first. Runs on the History worker,
/// which no frame waits on.
HistoryResults searchHistory(LoadedHistory loaded, HistoryFilters filters) {
  final query = foldForSearch(filters.query);
  final (:removedOnly, :shorts, :shortWatches, :music, :channels) = (
    removedOnly: filters.removedOnly,
    shorts: filters.shorts,
    shortWatches: filters.shortWatches,
    music: filters.music,
    channels: filters.channels,
  );

  final watches = loaded.history.watches;
  final channelOf = loaded.watchChannelIndex;
  final watchIndices = <int>[];
  for (var i = 0; i < watches.length; i++) {
    final watch = watches[i];
    if ((!removedOnly || watch.removedAt != null) &&
        (channels == null || channels.allows(channelOf[i])) &&
        _shows(shorts, shortWatches?.allows(i) ?? watch.isShort) &&
        _shows(music, watch.music) &&
        watch.matches(query)) {
      watchIndices.add(i);
    }
  }

  final searches = loaded.history.searches;
  final searchIndices = <int>[];
  for (var i = 0; i < searches.length; i++) {
    final search = searches[i];
    if ((!removedOnly || search.removedAt != null) &&
        search.searchText.contains(query)) {
      searchIndices.add(i);
    }
  }

  final watchedChannels = loaded.watchedChannels;
  final nameMatches = <int>{
    if (query.isNotEmpty)
      for (var c = 0; c < watchedChannels.length; c++)
        if (watchedChannels[c].searchText.contains(query)) c,
  };

  return (
    loaded: loaded,
    watchDays: groupByDay(watchIndices, loaded.watchDayKeys),
    searchDays: groupByDay(searchIndices, loaded.searchDayKeys),
    channelGroups: groupByChannel(
      channels: watchedChannels,
      watchChannelIndex: channelOf,
      watchIndices: watchIndices,
      nameMatches: nameMatches,
    ),
  );
}
