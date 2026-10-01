import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/prompt_videos.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

WatchEntry _watch(
  String id,
  DateTime time, {
  String channel = 'A',
  String? title,
  bool post = false,
  bool untitled = false,
}) => WatchEntry(
  time: time,
  kind: post ? WatchKind.post : WatchKind.video,
  title: untitled ? null : title ?? 'Video $id',
  url: post
      ? 'https://www.youtube.com/post/$id'
      : 'https://www.youtube.com/watch?v=$id',
  channelTitle: untitled ? null : channel,
);

/// [watches] as a loaded history, newest first as takeouts list them.
LoadedHistory _history(List<WatchEntry> watches) => LoadedHistory.of(
  TakeoutHistory(
    watches: [...watches]..sort((a, b) => b.time.compareTo(a.time)),
  ),
);

/// The picks of channel [channel], as the titles they name.
({List<String?> titles, List<String?> described}) _picked(
  LoadedHistory loaded, {
  String channel = 'A',
}) {
  final picks = pickPromptVideos(
    loaded,
  )[loaded.channelIndexByKey['name:$channel']!];
  final watches = loaded.history.watches;
  return (
    titles: [for (final i in picks.titles) watches[i].title],
    described: [for (final i in picks.described) watches[i].title],
  );
}

DateTime _day(int n) => DateTime.utc(2020).add(Duration(days: n));

void main() {
  test('with few videos, all are picked, a rewatch counted once', () {
    final loaded = _history([
      for (var i = 0; i < 5; i++) _watch('v$i', _day(i)),
      _watch('v2', _day(10)),
      _watch('v2', _day(11)),
    ]);

    final titles = _picked(loaded).titles;

    expect(titles, hasLength(5));
    expect(titles.toSet(), {for (var i = 0; i < 5; i++) 'Video v$i'});
  });

  test('the most rewatched come first, ties going to the more recent', () {
    final loaded = _history([
      for (var i = 0; i < 80; i++) _watch('v$i', _day(i)),
      for (var n = 0; n < 4; n++) _watch('v5', _day(100 + n)),
      for (var n = 0; n < 3; n++) _watch('v6', _day(110 + n)),
      for (var n = 0; n < 2; n++) _watch('v7', _day(120 + n)),
      for (var n = 0; n < 2; n++) _watch('v8', _day(130 + n)),
    ]);

    final titles = _picked(loaded).titles;

    expect(titles, hasLength(maxPromptTitles));
    expect(titles.take(4), ['Video v5', 'Video v6', 'Video v8', 'Video v7']);
  });

  test('picks are spread over the whole history, not the last weeks', () {
    final loaded = _history([
      for (var i = 0; i < 600; i++) _watch('v$i', _day(i * 3)),
    ]);
    final watches = loaded.history.watches;
    final picks = pickPromptVideos(loaded)[0];

    final years = [for (final i in picks.titles) watches[i].time.year];
    for (final year in [2020, 2021, 2022, 2023, 2024]) {
      expect(years.where((y) => y == year).length, greaterThan(3));
    }
    final oldest = picks.titles
        .map((i) => watches[i].time)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    expect(oldest.isBefore(_day(30)), isTrue);
  });

  test('the same history picks the same', () {
    List<WatchEntry> watches() => [
      for (var i = 0; i < 300; i++) _watch('v${i % 170}', _day(i)),
    ];

    final first = pickPromptVideos(_history(watches()))[0];
    final second = pickPromptVideos(_history(watches()))[0];

    expect(second.titles, first.titles);
    expect(second.described, first.described);
  });

  test('watched videos without a title are left out', () {
    final loaded = _history([
      _watch('kept', _day(1)),
      _watch('gone', _day(2), untitled: true),
    ]);

    expect(_picked(loaded).titles, ['Video kept']);
  });

  test('descriptions are picked from videos with an ID, spread over the '
      'titles', () {
    final loaded = _history([
      for (var i = 0; i < 70; i++) _watch('v$i', _day(i)),
      for (var i = 0; i < 20; i++) _watch('p$i', _day(200 + i), post: true),
    ]);

    final (:titles, :described) = _picked(loaded);

    expect(described, hasLength(maxPromptDescriptions));
    expect(described.every((t) => t!.startsWith('Video v')), isTrue);
    expect(titles, containsAll(described));
    // Spread over the titles with an ID, not bunched at either end.
    final withIds = [
      for (final t in titles)
        if (t!.startsWith('Video v')) t,
    ];
    final positions = [for (final t in described) withIds.indexOf(t!)];
    expect(positions.first, lessThan(withIds.length ~/ 10));
    expect(positions.last, greaterThan(withIds.length * 9 ~/ 10));
  });

  group('cleaning a description', () {
    test('removes links, hashtags and timestamps', () {
      final cleaned = cleanDescription(
        'Watch more: https://example.com/x and www.site.org/y #gaming '
        '#shorts\n00:00 Intro\n1:02:03 The end',
      )!;

      expect(cleaned, contains('Watch more'));
      expect(cleaned, contains('Intro'));
      expect(cleaned, contains('The end'));
      for (final gone in ['http', 'www', '#', '00:00', '1:02:03', '\n']) {
        expect(cleaned, isNot(contains(gone)), reason: gone);
      }
    });

    test('cuts a long one at a word', () {
      final cleaned = cleanDescription('word ' * 200)!;

      expect(cleaned.length, lessThanOrEqualTo(maxVideoDescription));
      expect(cleaned, endsWith('word'));
    });

    test('gives nothing when nothing is left', () {
      expect(cleanDescription('https://example.com #tag 12:34'), isNull);
      expect(cleanDescription(null), isNull);
    });
  });
}
