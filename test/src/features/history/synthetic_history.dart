import 'dart:math';
import 'dart:typed_data';

import 'package:youtube_takeout_manager/src/features/history/data/history_csv_codec.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

const _words = [
  'speedrun',
  'guide',
  'review',
  'live',
  'music',
  'remix',
  'news',
  'cooking',
  'travel',
  'vlog',
  'tutorial',
  'ranked',
  'highlights',
  'trailer',
  'asmr',
  'piano',
  'lofi',
  'challenge',
  'reaction',
  'podcast',
  'build',
  'retro',
];

/// A history the size of a heavy viewer's, built by code from [seed] so it's
/// the same each time: [watches] watched videos from [channels] channels,
/// the most watched far more than the rest, over eight years; about 5%
/// Shorts, 3% on YouTube Music, 2% removed and 1% with no channel; and
/// [searches] searches. Videos are rewatched now and then.
TakeoutHistory syntheticHistory({
  int watches = 64000,
  int channels = 12000,
  int searches = 20000,
  int seed = 7,
}) {
  final random = Random(seed);
  final start = DateTime.utc(2018);
  const span = Duration(days: 365 * 8);
  DateTime when() => start.add(
    Duration(seconds: (random.nextDouble() * span.inSeconds).floor()),
  );
  String words(int n) => [
    for (var i = 0; i < n; i++) _words[random.nextInt(_words.length)],
  ].join(' ');

  final watched = [
    for (var i = 0; i < watches; i++)
      () {
        final roll = random.nextDouble();
        final time = when();
        final removedAt = roll < 0.02
            ? time.add(const Duration(days: 30))
            : null;
        if (roll > 0.99) {
          // Removed before the export: no title, no channel.
          return WatchEntry(
            time: time,
            kind: WatchKind.video,
            url: 'https://www.youtube.com/watch?v=gone$i',
            removedAt: removedAt,
          );
        }
        // Zipf-like: a few channels are most of what's watched.
        final channel = (pow(random.nextDouble(), 2.5) * channels).floor();
        final video = 'c${channel}v${random.nextInt(60)}';
        final short = roll > 0.94 && roll <= 0.99;
        return WatchEntry(
          time: time,
          kind: WatchKind.video,
          music: roll >= 0.02 && roll < 0.05,
          title: '${words(4)} $video',
          url: short
              ? 'https://www.youtube.com/shorts/$video'
              : 'https://www.youtube.com/watch?v=$video',
          channelTitle: 'Channel $channel ${words(1)}',
          channelUrl: 'https://www.youtube.com/channel/UC$channel',
          removedAt: removedAt,
        );
      }(),
  ]..sort((a, b) => b.time.compareTo(a.time));
  final searched = [
    for (var i = 0; i < searches; i++)
      SearchEntry(
        time: when(),
        music: random.nextDouble() < 0.03,
        query: words(1 + random.nextInt(3)),
      ),
  ]..sort((a, b) => b.time.compareTo(a.time));
  return TakeoutHistory(
    watches: watched,
    searches: searched,
    watchesSnapshot: DateTime.utc(2026),
    searchesSnapshot: DateTime.utc(2026),
  );
}

/// [syntheticHistory] as the CSV files a takeout's folder keeps it in.
Map<String, Uint8List> syntheticHistoryFiles({
  int watches = 64000,
  int channels = 12000,
  int seed = 7,
}) => encodeHistoryCsvs(
  syntheticHistory(watches: watches, channels: channels, seed: seed),
);
