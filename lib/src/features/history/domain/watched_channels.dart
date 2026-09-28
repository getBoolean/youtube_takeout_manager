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
  Object get key => channelId ?? 'name:$title';

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

  /// How many videos were watched from it; when it was found by [byTitle],
  /// how many of those whose titles matched.
  final int count;
  final DateTime lastWatched;

  /// Found by a search for the titles of videos watched from it, not its
  /// name.
  final bool byTitle;

  /// Its name folded for search, worked out once.
  final String searchText;

  WatchedChannel({
    required this.channel,
    required this.count,
    required this.lastWatched,
    this.byTitle = false,
  }) : searchText = foldForSearch(channel.title);
}

/// The channels of the videos [watches] (newest first) were of, the most
/// watched first, marked [WatchedChannel.byTitle] when [byTitle] says the
/// videos were found by title. Videos with no channel, such as removed
/// ones, are left out.
List<WatchedChannel> countWatchedChannels(
  List<WatchEntry> watches, {
  bool byTitle = false,
}) {
  final counts = <Object, ({WatchEntry newest, int count})>{};
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
        byTitle: byTitle,
      ),
  ]..sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    return byCount != 0 ? byCount : a.channel.title.compareTo(b.channel.title);
  });
}
