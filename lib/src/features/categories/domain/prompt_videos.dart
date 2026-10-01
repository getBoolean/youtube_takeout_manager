import 'dart:math';

import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';

/// The most titles of videos watched from a channel an AI is told.
const maxPromptTitles = 60;

/// How many of those are the most rewatched, listed first.
const mostRewatchedFirst = 10;

/// The most video descriptions an AI is told, of those videos.
const maxPromptDescriptions = 10;

/// Video descriptions are cut to this many characters for an AI.
const maxVideoDescription = 300;

/// The videos picked to tell an AI about a channel, as indices into the
/// history's watched videos: [titles], and the ones of those whose
/// descriptions it's told.
typedef PromptPicks = ({List<int> titles, List<int> described});

/// A distinct video watched from a channel: its latest watch, as an index
/// into the history's watched videos (newest first), and how many times it
/// was watched.
class _Seen {
  final int latest;
  var count = 1;

  _Seen(this.latest);
}

/// For each of [loaded]'s watched channels, by its place in
/// `loaded.watchedChannels`, the videos to tell an AI about, spread over
/// everything watched from it rather than the last few weeks. A video
/// watched more than once counts once, by its latest watch; untitled ones
/// are left out.
///
/// The [mostRewatchedFirst] most rewatched come first (ties to the more
/// recent), then the rest spread evenly from oldest to newest, up to
/// [maxPromptTitles] in all; with no more than that, every one. The
/// [maxPromptDescriptions] described are spread over those titles the same
/// way, among the ones with a video ID. One pass over the history; the same
/// history always picks the same.
List<PromptPicks> pickPromptVideos(LoadedHistory loaded) {
  final seen = [
    for (var c = 0; c < loaded.watchedChannels.length; c++) <String, _Seen>{},
  ];
  final watches = loaded.history.watches;
  for (var i = 0; i < watches.length; i++) {
    final channel = loaded.watchChannelIndex[i];
    if (channel < 0) continue;
    final watch = watches[i];
    if (watch.title == null) continue;
    final key = watch.videoId ?? watch.url;
    // Newest first, so the first one met is the latest watch.
    final known = seen[channel][key];
    if (known == null) {
      seen[channel][key] = _Seen(i);
    } else {
      known.count++;
    }
  }

  return [
    for (final videos in seen)
      () {
        // In the order met: newest first.
        final newest = videos.values.toList();
        final byRewatches = [...newest]
          ..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            return byCount != 0 ? byCount : a.latest.compareTo(b.latest);
          });
        final first = byRewatches.take(mostRewatchedFirst).toList();
        final taken = first.toSet();
        final rest = [
          for (final video in newest.reversed)
            if (!taken.contains(video)) video,
        ];
        final titles = [
          for (final video in first) video.latest,
          for (final video in _spread(
            rest,
            min(maxPromptTitles - first.length, rest.length),
          ))
            video.latest,
        ];
        final withIds = [
          for (final i in titles)
            if (watches[i].videoId != null) i,
        ];
        return (
          titles: titles,
          described: _spread(
            withIds,
            min(maxPromptDescriptions, withIds.length),
          ),
        );
      }(),
  ];
}

/// [count] of [items], at even steps through them, each step's middle.
List<T> _spread<T>(List<T> items, int count) => [
  for (var j = 0; j < count; j++)
    items[((2 * j + 1) * items.length) ~/ (2 * count)],
];

final _link = RegExp(r'(?:https?://|www\.)\S+', caseSensitive: false);
final _hashtag = RegExp(r'#[\p{L}\p{N}_]+', unicode: true);
final _timestamp = RegExp(r'\b\d{1,2}:\d{2}(?::\d{2})?\b');
final _space = RegExp(r'\s+');

/// [description] as an AI is told it: without links, hashtags or
/// timestamps, on one line, cut to [maxVideoDescription] at a word; null
/// when nothing is left.
String? cleanDescription(String? description) {
  if (description == null) return null;
  final text = description
      .replaceAll(_link, ' ')
      .replaceAll(_hashtag, ' ')
      .replaceAll(_timestamp, ' ')
      .replaceAll(_space, ' ')
      .trim();
  if (text.isEmpty) return null;
  if (text.length <= maxVideoDescription) return text;
  final cut = text.substring(0, maxVideoDescription + 1);
  final lastSpace = cut.lastIndexOf(' ');
  return (lastSpace > 0
          ? cut.substring(0, lastSpace)
          : text.substring(0, maxVideoDescription))
      .trimRight();
}
