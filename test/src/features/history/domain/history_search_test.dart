import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/domain/channel_groups.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/history_search.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';

WatchEntry _watch(String title, int day, {required String channel}) =>
    WatchEntry(
      time: DateTime(2026, 4, day, 12).toUtc(),
      kind: WatchKind.video,
      title: title,
      url: 'https://www.youtube.com/watch?v=${title.hashCode}',
      channelTitle: channel,
    );

final _loaded = LoadedHistory.of(
  TakeoutHistory(
    watches: [
      _watch('Mario Kart record', 12, channel: 'MKWorld'),
      _watch('Tetris', 12, channel: 'Mario Kart Fans'),
      _watch('Another Mario Kart record', 11, channel: 'MKWorld'),
      _watch('Zelda', 10, channel: 'Shortcat'),
    ],
    searches: [
      SearchEntry(time: DateTime(2026, 4, 12).toUtc(), query: 'mario kart'),
      SearchEntry(time: DateTime(2026, 4, 11).toUtc(), query: 'zelda'),
    ],
  ),
);

HistoryFilters _filters({
  String query = '',
  bool removedOnly = false,
  ShowFilter shorts = ShowFilter.all,
  WatchMask? shortWatches,
  ShowFilter music = ShowFilter.all,
  ChannelMask? channels,
}) => (
  query: query,
  removedOnly: removedOnly,
  shorts: shorts,
  shortWatches: shortWatches,
  music: music,
  channels: channels,
);

List<(String, int)> _channelShape(ChannelGroups groups) => [
  for (final g in groups.groups) (g.channel?.title ?? g.key, g.indices.length),
];

/// A Short, a video on YouTube Music, and a video whose channel is gone.
final _mixed = LoadedHistory.of(
  TakeoutHistory(
    watches: [
      WatchEntry(
        time: DateTime(2026, 4, 12, 12).toUtc(),
        kind: WatchKind.video,
        title: 'A short',
        url: 'https://www.youtube.com/shorts/s1',
        channelTitle: 'Shorty',
        channelUrl: 'https://www.youtube.com/channel/UCs',
      ),
      WatchEntry(
        time: DateTime(2026, 4, 12, 11).toUtc(),
        kind: WatchKind.video,
        music: true,
        title: 'A song',
        url: 'https://music.youtube.com/watch?v=m1',
        channelTitle: 'Singer',
        channelUrl: 'https://www.youtube.com/channel/UCm',
      ),
      WatchEntry(
        time: DateTime(2026, 4, 12, 10).toUtc(),
        kind: WatchKind.video,
        url: 'https://www.youtube.com/watch?v=gone',
      ),
    ],
  ),
);

Future<List<String?>> _mixedTitles(HistoryFilters filters) async {
  final results = (await searchHistory(_mixed, filters))!;
  return [
    for (final d in results.watchDays)
      for (final i in d.indices) _mixed.history.watches[i].title,
  ];
}

void main() {
  test('without filters the whole history is shown, worked out on loading', () {
    final results = defaultResults(_loaded);

    expect(results.watchDays.expand((d) => d.indices), [0, 1, 2, 3]);
    expect(results.watchDays, hasLength(3));
    expect(results.searchDays.expand((d) => d.indices), [0, 1]);
    expect(_channelShape(results.channelGroups), [
      ('MKWorld', 2),
      ('Mario Kart Fans', 1),
      ('Shortcat', 1),
    ]);
  });

  test('narrows every list to the search', () async {
    final results = (await searchHistory(
      _loaded,
      _filters(query: 'mario kart'),
    ))!;

    expect(results.watchDays.expand((d) => d.indices), [0, 1, 2]);
    expect(results.searchDays.expand((d) => d.indices), [0]);
    // Channels named for it first, then by how many of their videos match.
    expect(_channelShape(results.channelGroups), [
      ('Mario Kart Fans', 1),
      ('MKWorld', 2),
    ]);
  });

  test('Shorts can be shown alone or hidden', () async {
    expect(await _mixedTitles(_filters(shorts: ShowFilter.only)), ['A short']);
    expect(await _mixedTitles(_filters(shorts: ShowFilter.hide)), [
      'A song',
      null,
    ]);
  });

  test('Shorts told apart by their format count, as well as ones watched '
      'through a Shorts link', () async {
    // The song turned out to be a Short too.
    final shorts = WatchMask(Uint8List.fromList([1, 1, 0]));

    expect(
      await _mixedTitles(
        _filters(shorts: ShowFilter.only, shortWatches: shorts),
      ),
      ['A short', 'A song'],
    );
  });

  test(
    'videos watched on YouTube Music can be shown alone or hidden',
    () async {
      expect(await _mixedTitles(_filters(music: ShowFilter.only)), ['A song']);
      expect(await _mixedTitles(_filters(music: ShowFilter.hide)), [
        'A short',
        null,
      ]);
    },
  );

  test("a channel filter keeps its channels' videos, and none without a "
      'channel', () async {
    final shorty = _mixed.channelIndexByKey['UCs']!;
    final mask = ChannelMask(
      Uint8List(_mixed.watchedChannels.length)..[shorty] = 1,
    );

    expect(await _mixedTitles(_filters(channels: mask)), ['A short']);
  });

  test('videos without a channel are grouped last', () {
    expect(_channelShape(defaultResults(_mixed).channelGroups).last, (
      noChannelGroupKey,
      1,
    ));
  });

  test('the history knows how many Shorts and Music videos it has', () {
    expect((_mixed.shortCount, _mixed.musicCount), (1, 1));
  });

  test('works in slices, pausing between them for frames', () async {
    var pauses = 0;
    final results = await searchHistory(
      _loaded,
      _filters(query: 'mario'),
      sliceSize: 1,
      pause: () async => pauses++,
    );

    expect(pauses, greaterThan(1));
    expect(results!.watchDays.expand((d) => d.indices), [0, 1, 2]);
  });

  test('stops when a newer search replaces it', () async {
    var cancelled = false;
    final results = await searchHistory(
      _loaded,
      _filters(query: 'mario'),
      sliceSize: 1,
      pause: () async => cancelled = true,
      cancelled: () => cancelled,
    );

    expect(results, isNull);
  });
}
