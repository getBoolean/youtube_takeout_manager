import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/prompt_videos.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_csv_codec.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_service.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/history_wire.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';

WatchEntry _watch(
  String id,
  String title,
  String channelId,
  String channel, {
  required int day,
}) => WatchEntry(
  time: DateTime.utc(2026, 4, day),
  kind: WatchKind.video,
  title: title,
  url: 'https://www.youtube.com/watch?v=$id',
  channelTitle: channel,
  channelUrl: 'https://www.youtube.com/channel/$channelId',
);

final _history = TakeoutHistory(
  watches: [
    _watch('kart0000001', 'Speedrun of Mario Kart', 'UCa', 'Karting', day: 14),
    _watch('cover000001', 'A cover of a song', 'UCb', 'rachie', day: 13),
    _watch('kart0000002', 'Mario Kart in a minute', 'UCa', 'Karting', day: 12),
  ],
  searches: [SearchEntry(time: DateTime.utc(2026, 4, 11), query: 'kart world')],
);

final _files = encodeHistoryCsvs(_history);

/// The titles of the watched videos [matches] shows, in its order.
List<String?> _titles(HistoryRows rows, HistoryMatches matches) => [
  for (final i in matches.watchIndices) rows.watchTitles[i],
];

/// [picks] as plain lists, to compare.
List<List<List<int>>> _plain(List<PromptPicks> picks) => [
  for (final (:titles, :described) in picks)
    [titles.toList(), described.toList()],
];

void main() {
  late HistoryService service;
  late HistoryRows rows;

  Future<HistoryMatches> search(
    HistoryQuery query, {
    int generation = 1,
  }) async =>
      HistoryMatches.fromWire(await service.search(query.toWire(), generation));

  setUp(() async {
    service = HistoryService();
    rows = HistoryRows.fromWire(await service.load(_files));
  });

  test('loads saved history and gives back what showing it needs', () {
    expect(rows.watchTitles, [
      'Speedrun of Mario Kart',
      'A cover of a song',
      'Mario Kart in a minute',
    ]);
    expect(rows.channelTitles, unorderedEquals(['Karting', 'rachie']));
    expect(rows.searchQueries, ['kart world']);
    expect(rows.all.watchIndices, hasLength(3));
  });

  test(
    'searches what it loaded, answering with the generation asked',
    () async {
      final matches = await search(
        const HistoryQuery(query: 'mario'),
        generation: 7,
      );

      expect(matches.generation, 7);
      expect(_titles(rows, matches), [
        'Speedrun of Mario Kart',
        'Mario Kart in a minute',
      ]);
      expect(matches.searchIndices, isEmpty);
      expect((await search(const HistoryQuery(query: 'kart'))).searchIndices, [
        0,
      ]);
    },
  );

  test('narrows to the channels picked', () async {
    final mask = Uint8List(rows.channelTitles.length)
      ..[rows.channelTitles.indexOf('rachie')] = 1;

    final matches = await search(HistoryQuery(channelMask: mask));

    expect(_titles(rows, matches), ['A cover of a song']);
  });

  test('counts as Shorts the videos it is told are', () async {
    expect(await service.setShortVideos(['cover000001']), 1);

    final shorts = await search(const HistoryQuery(shorts: ShowFilter.only));
    final counts = await service.channelWatchCounts(
      ShowFilter.hide.index,
      ShowFilter.all.index,
    );

    expect(_titles(rows, shorts), ['A cover of a song']);
    expect(counts[rows.channelTitles.indexOf('rachie')], 0);
    expect(counts[rows.channelTitles.indexOf('Karting')], 2);
  });

  test(
    'keeps the Shorts it was told of for the next history it loads',
    () async {
      await service.setShortVideos(['cover000001']);

      rows = HistoryRows.fromWire(await service.load(_files));
      final shorts = await search(const HistoryQuery(shorts: ShowFilter.only));

      expect(_titles(rows, shorts), ['A cover of a song']);
    },
  );

  test('loads with the videos to tell AI about picked, as they would be '
      'picked in place', () {
    expect(
      _plain(LoadedHistory.fromRows(rows).promptPicks),
      _plain(pickPromptVideos(loadSavedHistory(_files))),
    );
  });

  test('asked before a history is loaded, it says so', () {
    expect(
      HistoryService().search(const HistoryQuery().toWire(), 1),
      throwsStateError,
    );
  });

  test('runs in a worker of its own', () async {
    final worker = HistoryServiceWorker();
    addTearDown(worker.stop);

    final rows = HistoryRows.fromWire(await worker.load(_files));
    final matches = HistoryMatches.fromWire(
      await worker.search(const HistoryQuery(query: 'cover').toWire(), 3),
    );

    expect(matches.generation, 3);
    expect(_titles(rows, matches), ['A cover of a song']);
    expect(
      _plain(LoadedHistory.fromRows(rows).promptPicks),
      _plain(pickPromptVideos(loadSavedHistory(_files))),
    );
  });
}
