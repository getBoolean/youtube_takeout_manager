import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/prompt_videos.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/history_search.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/history_wire.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';

WatchEntry _watch(
  String id,
  DateTime time, {
  String? channel = 'Gamer',
  bool music = false,
  bool short = false,
  bool post = false,
  DateTime? removedAt,
}) => WatchEntry(
  time: time,
  kind: post ? WatchKind.post : WatchKind.video,
  music: music,
  title: channel == null ? null : 'Video $id',
  url: post
      ? 'https://www.youtube.com/post/$id'
      : short
      ? 'https://www.youtube.com/shorts/$id'
      : 'https://www.youtube.com/watch?v=$id',
  channelTitle: channel,
  channelUrl: channel == null
      ? null
      : 'https://www.youtube.com/channel/UC${channel.toLowerCase()}',
  removedAt: removedAt,
);

/// Newest first, with something of every kind: Shorts, Music, a post, a
/// removed one, one with no channel, two channels, over three days.
final _history = TakeoutHistory(
  watches: [
    _watch('a', DateTime.utc(2026, 9, 3, 12)),
    _watch('b', DateTime.utc(2026, 9, 3, 11), short: true),
    _watch('c', DateTime.utc(2026, 9, 2, 12), channel: 'Singer', music: true),
    _watch('d', DateTime.utc(2026, 9, 2, 11), channel: null),
    _watch('e', DateTime.utc(2026, 9, 1, 12), post: true),
    _watch(
      'a',
      DateTime.utc(2026, 9, 1, 11),
      removedAt: DateTime.utc(2026, 9, 20),
    ),
  ],
  searches: [
    SearchEntry(time: DateTime.utc(2026, 9, 3), query: 'speedrun'),
    SearchEntry(
      time: DateTime.utc(2026, 9, 2),
      query: 'jazz',
      music: true,
      removedAt: DateTime.utc(2026, 9, 20),
    ),
  ],
  watchesSnapshot: DateTime.utc(2026, 9, 21),
);

void main() {
  group("a history's rows", () {
    final loaded = LoadedHistory.of(_history);

    HistoryRows roundTrip(LoadedHistory loaded) =>
        HistoryRows.fromWire(HistoryRows.of(loaded).toWire());

    test('give back every watched video and search as it was', () {
      final history = roundTrip(loaded).toHistory();

      expect(history.watches, _history.watches);
      expect(history.searches, _history.searches);
      expect(history.watchesSnapshot, _history.watchesSnapshot);
      expect(history.searchesSnapshot, isNull);
    });

    test("give back what was worked out from them: days, channels, counts", () {
      final rows = roundTrip(loaded);

      expect(rows.watchDayKeys, loaded.watchDayKeys);
      expect(rows.searchDayKeys, loaded.searchDayKeys);
      expect(rows.watchChannelIndex, loaded.watchChannelIndex);
      expect(
        [for (final c in rows.watchedChannels()) (c.channel, c.count)],
        [for (final c in loaded.watchedChannels) (c.channel, c.count)],
      );
      expect(rows.recentChannelIds, loaded.recentChannelIds);
      expect(
        (
          rows.removedWatchCount,
          rows.removedSearchCount,
          rows.shortCount,
          rows.musicCount,
        ),
        (
          loaded.removedWatchCount,
          loaded.removedSearchCount,
          loaded.shortCount,
          loaded.musicCount,
        ),
      );
    });

    test('of an empty history are empty', () {
      final history = roundTrip(LoadedHistory.empty).toHistory();

      expect(history.isEmpty, isTrue);
    });

    test('make each entry only when it is first looked at', () {
      final history = roundTrip(loaded).toHistory();

      expect(identical(history.watches[2], history.watches[2]), isTrue);
    });
  });

  test('what is searched for comes across as it was', () {
    for (final query in [
      HistoryQuery(
        query: 'speed',
        removedOnly: true,
        shorts: ShowFilter.hide,
        music: ShowFilter.only,
        channelMask: Uint8List.fromList([1, 0, 1]),
      ),
      const HistoryQuery(),
    ]) {
      final wired = HistoryQuery.fromWire(query.toWire());

      expect(wired.query, query.query);
      expect(wired.removedOnly, query.removedOnly);
      expect(wired.shorts, query.shorts);
      expect(wired.music, query.music);
      expect(wired.channelMask, query.channelMask);
    }
  });

  group('what a search shows', () {
    final loaded = LoadedHistory.of(_history);
    final results = defaultResults(loaded);

    HistoryMatches roundTrip(HistoryResults results) => HistoryMatches.fromWire(
      HistoryMatches.of(results, generation: 3).toWire(),
    );

    test('comes back by day, month and channel as it was found', () {
      final matches = roundTrip(results);

      expect(matches.generation, 3);
      expect(
        [
          for (final d in matches.watchDays()) [d.dayKey, d.day, d.indices],
        ],
        [
          for (final d in results.watchDays) [d.dayKey, d.day, d.indices],
        ],
      );
      expect(
        [
          for (final d in matches.searchDays()) [d.dayKey, d.indices],
        ],
        [
          for (final d in results.searchDays) [d.dayKey, d.indices],
        ],
      );
      expect(matches.watchMonths(), hasLength(1));
      final groups = matches.channelGroups(loaded.watchedChannels).groups;
      expect(
        [
          for (final g in groups) [g.key, g.channel, g.indices],
        ],
        [
          for (final g in results.channelGroups.groups)
            [g.key, g.channel, g.indices],
        ],
      );
    });

    test('groups are views of one list, not copies', () {
      final matches = roundTrip(results);

      final day = matches.watchDays().first.indices;
      matches.watchIndices[0] = 99;

      expect(day.first, 99);
    });

    test('channel groups still find where a video is', () {
      final groups = roundTrip(results).channelGroups(loaded.watchedChannels);

      expect(
        groups.locate(5, loaded.watchChannelIndex),
        results.channelGroups.locate(5, loaded.watchChannelIndex),
      );
    });
  });

  test('the videos picked for AI come across as they were', () {
    final picks = pickPromptVideos(LoadedHistory.of(_history));

    final wired = promptPicksFromWire(promptPicksToWire(picks));

    expect(
      [
        for (final p in wired) [p.titles, p.described],
      ],
      [
        for (final p in picks) [p.titles, p.described],
      ],
    );
  });
}
