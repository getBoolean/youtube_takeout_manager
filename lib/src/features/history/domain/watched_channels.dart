import 'package:dart_mappable/dart_mappable.dart';

import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

import 'watch_entry.dart';

part 'watched_channels.mapper.dart';

/// A channel in the watch history: an uploader of videos watched.
@MappableClass()
class HistoryChannel with HistoryChannelMappable {
  /// Null when the history only gives its name.
  final String? channelId;
  final String title;
  final String? channelUrl;

  const HistoryChannel({this.channelId, required this.title, this.channelUrl});

  /// [watch]'s channel, or null when it has none (e.g. a removed video).
  static HistoryChannel? of(WatchEntry watch) => switch (watch.channelTitle) {
    final title? => HistoryChannel(
      channelId: watch.channelId,
      title: title,
      channelUrl: watch.channelUrl,
    ),
    null => null,
  };

  /// Tells it apart from other channels: its ID, or its name without one.
  String get key => channelId ?? 'name:$title';

  /// Whether [watch] is of a video of this channel: by channel ID when it
  /// has one, else by name.
  bool matches(WatchEntry watch) => channelId != null
      ? watch.channelId == channelId
      : watch.channelId == null && watch.channelTitle == title;
}

/// A channel videos were watched from, and how many.
class WatchedChannel {
  /// Named as it was when a video of it was last watched.
  final HistoryChannel channel;

  /// How many videos were watched from it.
  final int count;
  final DateTime lastWatched;

  /// Its name folded for search, worked out once.
  final String searchText;

  WatchedChannel({
    required this.channel,
    required this.count,
    required this.lastWatched,
  }) : searchText = foldForSearch(channel.title);
}

/// Orders channels the most watched first, then by name.
int compareWatchedChannels(WatchedChannel a, WatchedChannel b) {
  final byCount = b.count.compareTo(a.count);
  return byCount != 0 ? byCount : a.channel.title.compareTo(b.channel.title);
}

/// The channels of the videos [watches] (newest first) were of, the most
/// watched first. Videos with no channel, such as removed ones, are left
/// out.
List<WatchedChannel> countWatchedChannels(List<WatchEntry> watches) {
  final counts = <String, ({WatchEntry newest, int count})>{};
  for (final watch in watches) {
    final key = HistoryChannel.of(watch)?.key;
    if (key == null) continue;
    final seen = counts[key];
    counts[key] = (
      newest: seen?.newest ?? watch,
      count: (seen?.count ?? 0) + 1,
    );
  }
  return [
    for (final (:newest, :count) in counts.values)
      WatchedChannel(
        channel: HistoryChannel.of(newest)!,
        count: count,
        lastWatched: newest.time,
      ),
  ]..sort(compareWatchedChannels);
}
