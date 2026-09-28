import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/domain/history_search.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';

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
  HistoryChannel? channel,
  bool removedOnly = false,
}) => (query: query, channel: channel, removedOnly: removedOnly);

void main() {
  test('without filters the whole history is shown, worked out on loading', () {
    final results = defaultResults(_loaded);

    expect(results.watchDays.expand((d) => d.indices), [0, 1, 2, 3]);
    expect(results.watchDays, hasLength(3));
    expect(results.searchDays.expand((d) => d.indices), [0, 1]);
    expect(
      [for (final c in results.channels) c.channel.title],
      ['MKWorld', 'Mario Kart Fans', 'Shortcat'],
    );
  });

  test('narrows every list to the search', () async {
    final results = (await searchHistory(
      _loaded,
      _filters(query: 'mario kart'),
    ))!;

    expect(results.watchDays.expand((d) => d.indices), [0, 1, 2]);
    expect(results.searchDays.expand((d) => d.indices), [0]);
    expect(
      [for (final c in results.channels) (c.channel.title, c.count, c.byTitle)],
      [('Mario Kart Fans', 1, false), ('MKWorld', 2, true)],
    );
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
