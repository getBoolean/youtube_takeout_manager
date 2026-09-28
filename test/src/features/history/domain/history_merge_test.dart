import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/domain/history_merge.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

final _march = DateTime.utc(2026, 3);
final _april = DateTime.utc(2026, 4);

WatchEntry _watch(String id, DateTime time, {DateTime? removedAt}) =>
    WatchEntry(
      time: time,
      kind: WatchKind.video,
      url: 'https://www.youtube.com/watch?v=$id',
      title: 'Video $id',
      channelTitle: 'Channel',
      channelUrl: 'https://www.youtube.com/channel/UCchannel',
      removedAt: removedAt,
    );

SearchEntry _search(String query, DateTime time, {DateTime? removedAt}) =>
    SearchEntry(time: time, query: query, removedAt: removedAt);

final _a = DateTime.utc(2026, 1, 1, 10);
final _b = DateTime.utc(2026, 1, 2, 10);
final _c = DateTime.utc(2026, 1, 3, 10);

/// History saved from an export made at [snapshot].
TakeoutHistory _saved({
  List<WatchEntry> watches = const [],
  List<SearchEntry> searches = const [],
  DateTime? snapshot,
}) => TakeoutHistory(
  watches: watches,
  searches: searches,
  watchesSnapshot: watches.isEmpty ? null : snapshot,
  searchesSnapshot: searches.isEmpty ? null : snapshot,
);

ExportHistory _picked({
  List<WatchEntry>? watches,
  List<SearchEntry>? searches,
  DateTime? exportedAt,
  int skippedWatchRows = 0,
  bool watchesUnreadable = false,
}) => ExportHistory(
  exportedAt: exportedAt,
  watches: watches == null
      ? null
      : HistoryFileRead(
          entries: watches,
          skippedRows: skippedWatchRows,
          unreadable: watchesUnreadable,
        ),
  searches: searches == null ? null : HistoryFileRead(entries: searches),
);

List<String?> _titles(List<WatchEntry> watches) => [
  for (final w in watches) w.title,
];

void main() {
  test('an entry in both an HTML and a JSON export is kept once', () {
    // JSON times have milliseconds; HTML's stop at the second.
    final json = _watch('x', DateTime.utc(2026, 1, 1, 10, 0, 0, 123));
    final html = _watch('x', DateTime.utc(2026, 1, 1, 10));

    final plan = planHistoryImport(
      picked: [
        _picked(watches: [json], exportedAt: _march),
        _picked(watches: [html], exportedAt: _april),
      ],
    );

    expect(plan.merged!.watches, hasLength(1));
  });

  test('merged entries are newest first', () {
    final plan = planHistoryImport(
      picked: [
        _picked(
          watches: [_watch('a', _a), _watch('c', _c)],
          exportedAt: _march,
        ),
        _picked(watches: [_watch('b', _b)], exportedAt: _april),
      ],
    );

    expect(_titles(plan.merged!.watches), ['Video c', 'Video b', 'Video a']);
  });

  test('entries only an older export has are kept and marked removed', () {
    final plan = planHistoryImport(
      saved: _saved(
        watches: [_watch('b', _b), _watch('a', _a)],
        snapshot: _march,
      ),
      picked: [
        _picked(watches: [_watch('b', _b)], exportedAt: _april),
      ],
    );

    final watches = plan.merged!.watches;
    expect(_titles(watches), ['Video b', 'Video a']);
    expect(watches[0].removedAt, isNull);
    expect(watches[1].removedAt, _april);
    expect(plan.newlyRemovedWatchCount, 1);
    expect(plan.newWatchCount, 0);
  });

  test('an entry already marked removed keeps when it was first missed', () {
    final plan = planHistoryImport(
      saved: _saved(
        watches: [
          _watch('b', _b),
          _watch('a', _a, removedAt: _march),
        ],
        snapshot: _march,
      ),
      picked: [
        _picked(watches: [_watch('b', _b)], exportedAt: _april),
      ],
    );

    expect(plan.merged!.watches[1].removedAt, _march);
    expect(plan.newlyRemovedWatchCount, 0);
  });

  test('an entry that reappears is unmarked', () {
    final plan = planHistoryImport(
      saved: _saved(
        watches: [_watch('a', _a, removedAt: _march)],
        snapshot: _march,
      ),
      picked: [
        _picked(watches: [_watch('a', _a)], exportedAt: _april),
      ],
    );

    expect(plan.merged!.watches.single.removedAt, isNull);
  });

  test('entries the saved history lacked count as new', () {
    final plan = planHistoryImport(
      saved: _saved(watches: [_watch('a', _a)], snapshot: _march),
      picked: [
        _picked(
          watches: [_watch('c', _c), _watch('b', _b), _watch('a', _a)],
          exportedAt: _april,
        ),
      ],
    );

    expect(plan.newWatchCount, 2);
    expect(plan.merged!.watches, hasLength(3));
  });

  test(
    'an older takeout picked after a newer one marks its extras removed',
    () {
      final plan = planHistoryImport(
        saved: _saved(watches: [_watch('b', _b)], snapshot: _april),
        picked: [
          _picked(
            watches: [_watch('b', _b), _watch('a', _a)],
            exportedAt: _march,
          ),
        ],
      );

      final watches = plan.merged!.watches;
      expect(watches[0].removedAt, isNull);
      expect(watches[1].removedAt, _april);
      expect(plan.merged!.watchesSnapshot, _april);
    },
  );

  test("removal isn't marked when the newest history had unreadable rows", () {
    final plan = planHistoryImport(
      saved: _saved(
        watches: [_watch('b', _b), _watch('a', _a)],
        snapshot: _march,
      ),
      picked: [
        _picked(
          watches: [_watch('b', _b)],
          exportedAt: _april,
          skippedWatchRows: 1,
        ),
      ],
    );

    expect(plan.merged!.watches.map((w) => w.removedAt), everyElement(isNull));
    expect(plan.removalCheckSkipped, isTrue);
    expect(plan.skippedRows, 1);
    expect(plan.needsReview, isTrue);
  });

  test('an unreadable history file keeps everything saved, unmarked', () {
    final plan = planHistoryImport(
      saved: _saved(watches: [_watch('a', _a)], snapshot: _march),
      picked: [
        _picked(watches: const [], exportedAt: _april, watchesUnreadable: true),
      ],
    );

    expect(plan.merged!.watches.single.removedAt, isNull);
    expect(plan.unreadableFiles, 1);
    expect(plan.removalCheckSkipped, isTrue);
  });

  test('no picked history leaves the saved history unchanged', () {
    final plan = planHistoryImport(
      saved: _saved(watches: [_watch('a', _a)], snapshot: _march),
      picked: [_picked(exportedAt: _april)],
    );

    expect(plan.merged, isNull);
    expect(plan.needsReview, isFalse);
  });

  test('a kind the takeout lacks keeps its saved entries unmarked', () {
    final plan = planHistoryImport(
      saved: _saved(
        watches: [_watch('a', _a)],
        searches: [_search('cats', _a)],
        snapshot: _march,
      ),
      picked: [
        _picked(searches: [_search('dogs', _b)], exportedAt: _april),
      ],
    );

    final merged = plan.merged!;
    expect(merged.watches.single.removedAt, isNull);
    expect(merged.watchesSnapshot, _march);
    expect([for (final s in merged.searches) s.query], ['dogs', 'cats']);
    expect(merged.searches[1].removedAt, _april);
    expect(plan.newSearchCount, 1);
    expect(plan.newlyRemovedSearchCount, 1);
  });

  test("a renamed zip's history dates from its newest entry", () {
    final plan = planHistoryImport(
      saved: _saved(watches: [_watch('a', _a)], snapshot: _march),
      picked: [
        // No export time, and every entry is older than the saved export.
        _picked(watches: [_watch('b', _b)]),
      ],
    );

    final watches = plan.merged!.watches;
    expect(watches.firstWhere((w) => w.title == 'Video a').removedAt, isNull);
    expect(watches.firstWhere((w) => w.title == 'Video b').removedAt, _march);
  });

  group("a removed video's title and channel", () {
    // A takeout made after a video is deleted or made private lists it by
    // its link only.
    WatchEntry unavailable(String id, DateTime time) => WatchEntry(
      time: time,
      kind: WatchKind.video,
      url: _watch(id, time).url,
    );

    test('survive a newer takeout that only has its link', () {
      final plan = planHistoryImport(
        saved: _saved(watches: [_watch('x', _a)], snapshot: _march),
        picked: [
          _picked(watches: [unavailable('x', _a)], exportedAt: _april),
        ],
      );

      final watch = plan.merged!.watches.single;
      expect(watch.title, 'Video x');
      expect(watch.channelTitle, 'Channel');
      expect(watch.channelId, 'UCchannel');
    });

    test('are filled in from an older takeout picked later', () {
      final plan = planHistoryImport(
        saved: _saved(watches: [unavailable('x', _a)], snapshot: _april),
        picked: [
          _picked(watches: [_watch('x', _a)], exportedAt: _march),
        ],
      );

      expect(plan.merged!.watches.single.title, 'Video x');
    });
  });

  test("an unreadable newest history doesn't date the saved history", () {
    final plan = planHistoryImport(
      saved: _saved(watches: [_watch('a', _a)], snapshot: _march),
      picked: [
        _picked(
          watches: [_watch('b', _b)],
          exportedAt: _april,
          skippedWatchRows: 1,
        ),
      ],
    );

    expect(plan.merged!.watchesSnapshot, _march);
  });

  test('saved history whose export time was lost still takes part', () {
    final plan = planHistoryImport(
      saved: TakeoutHistory(watches: [_watch('a', _a)]),
      picked: [
        _picked(watches: [_watch('b', _b)], exportedAt: _april),
      ],
    );

    expect(
      [for (final w in plan.merged!.watches) w.title],
      ['Video b', 'Video a'],
    );
  });
}
