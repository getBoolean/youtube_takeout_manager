import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squadron/squadron.dart';

import 'package:youtube_takeout_manager/src/features/history/data/history_csv_codec.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_engine.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_service.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/history_wire.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

WatchEntry _watch(String id, String title) => WatchEntry(
  time: DateTime.utc(2026, 4, 12),
  kind: WatchKind.video,
  title: title,
  url: 'https://www.youtube.com/watch?v=$id',
  channelTitle: 'Karting',
  channelUrl: 'https://www.youtube.com/channel/UCa',
);

final _files = encodeHistoryCsvs(
  TakeoutHistory(
    watches: [
      _watch('kart0000001', 'Speedrun of Mario Kart'),
      _watch('cover000001', 'A cover of a song'),
    ],
  ),
);

/// History whose first [failures] searches fail, as a squadron worker
/// passes errors on; [dead] says whether the worker behind it died. Keeps
/// what it was given.
final class _Fake extends HistoryService {
  int failures;
  bool dead;
  final Completer<void>? hold;
  final loaded = <Map<String, Uint8List>>[];
  final shorts = <List<String>>[];

  _Fake({this.failures = 0, this.dead = false, this.hold});

  @override
  Future<List<Object?>> load(Map<String, Uint8List> files) {
    loaded.add(files);
    return super.load(files);
  }

  @override
  Future<int> setShortVideos(List<String> videoIds) {
    shorts.add(videoIds);
    return super.setShortVideos(videoIds);
  }

  @override
  Future<List<Object?>> search(List<Object?> query, int generation) async {
    await hold?.future;
    if (failures-- > 0) throw WorkerException('failed');
    return super.search(query, generation);
  }
}

void main() {
  bool died(HistoryService service) => (service as _Fake).dead;

  /// The titles of what [engine] finds for [query].
  Future<List<String?>> find(HistoryEngine engine, String query) async {
    final rows = await engine.load(_files);
    final matches = await engine.search(HistoryQuery(query: query), 1);
    return [for (final i in matches.watchIndices) rows.watchTitles[i]];
  }

  test('loads and searches on a worker started once, on first use', () async {
    final started = <_Fake>[];
    final engine = WorkerHistoryEngine(
      () async => _Fake()..also(started.add),
      isDead: died,
    );
    expect(started, isEmpty);

    expect(await find(engine, 'cover'), ['A cover of a song']);
    expect(await find(engine, 'speedrun'), ['Speedrun of Mario Kart']);
    expect(started, hasLength(1));
  });

  test('a search that fails is passed on, and the worker kept', () async {
    final started = <_Fake>[];
    final engine = WorkerHistoryEngine(
      () async => _Fake(failures: 1)..also(started.add),
      isDead: died,
    );
    await engine.load(_files);

    await expectLater(
      engine.search(const HistoryQuery(query: 'cover'), 1),
      throwsA(isA<WorkerException>()),
    );
    expect(await find(engine, 'cover'), ['A cover of a song']);
    expect(started, hasLength(1));
  });

  test('a worker that died mid-search is replaced, the history loaded into '
      'it again with the Shorts it was told of, and the search '
      'answered', () async {
    final started = <_Fake>[];
    final engine = WorkerHistoryEngine(() async {
      final fake = started.isEmpty ? _Fake(failures: 1, dead: true) : _Fake();
      started.add(fake);
      return fake;
    }, isDead: died);
    final rows = await engine.load(_files);
    await engine.setShortVideos(['cover000001']);

    final matches = await engine.search(const HistoryQuery(query: 'cover'), 4);

    expect(matches.generation, 4);
    expect(
      [for (final i in matches.watchIndices) rows.watchTitles[i]],
      ['A cover of a song'],
    );
    expect(started, hasLength(2));
    expect(started.last.loaded, [_files]);
    expect(started.last.shorts, [
      ['cover000001'],
    ]);
  });

  test('dying again throws HistoryWorkerDied, and the next call starts a '
      'new worker', () async {
    final started = <_Fake>[];
    final engine = WorkerHistoryEngine(() async {
      final fake = started.length < 2
          ? _Fake(failures: 1, dead: true)
          : _Fake();
      started.add(fake);
      return fake;
    }, isDead: died);
    await engine.load(_files);

    await expectLater(
      engine.search(const HistoryQuery(query: 'cover'), 1),
      throwsA(isA<HistoryWorkerDied>()),
    );
    expect(started, hasLength(2));

    expect(await find(engine, 'cover'), ['A cover of a song']);
    expect(started, hasLength(3));
  });

  test('searches under way when the worker dies are all answered by one '
      'replacement', () async {
    final hold = Completer<void>();
    final started = <_Fake>[];
    final engine = WorkerHistoryEngine(() async {
      final fake = started.isEmpty
          ? _Fake(failures: 2, dead: true, hold: hold)
          : _Fake();
      started.add(fake);
      return fake;
    }, isDead: died);
    final rows = await engine.load(_files);

    final first = engine.search(const HistoryQuery(query: 'cover'), 1);
    final second = engine.search(const HistoryQuery(query: 'speedrun'), 2);
    await pumpEventQueue();
    hold.complete();

    final [a, b] = await Future.wait([first, second]);
    expect(
      [for (final i in a.watchIndices) rows.watchTitles[i]],
      ['A cover of a song'],
    );
    expect(
      [for (final i in b.watchIndices) rows.watchTitles[i]],
      ['Speedrun of Mario Kart'],
    );
    expect(started, hasLength(2));
  });

  test('in-process, it finds what the worker finds', () async {
    expect(await find(LocalHistoryEngine(), 'cover'), ['A cover of a song']);
  });

  test('tests run History in-process', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(historyEngineProvider), isA<LocalHistoryEngine>());
  });
}

extension<T> on T {
  /// Hands this to [use], for a builder's cascade.
  void also(void Function(T value) use) => use(this);
}
