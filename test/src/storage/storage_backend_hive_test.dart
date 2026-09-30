import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_backend_hive.dart';

void main() {
  late Directory dir;
  late DateTime time;
  HiveBackend? open;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_backend');
    time = DateTime(2026, 9, 30);
  });

  tearDown(() async {
    await open?.close();
    open = null;
    await dir.delete(recursive: true);
  });

  Future<HiveBackend> backend({int capBytes = 30, int trimToBytes = 20}) async {
    await open?.close();
    return open = await HiveBackend.open(
      dir.path,
      capBytes: capBytes,
      trimToBytes: trimToBytes,
      touchEvery: Duration.zero,
      now: () => time,
    );
  }

  Uint8List bytes(int length) => Uint8List(length);

  test('entries are kept by box and read back after reopening', () async {
    await (await backend()).putAll(EntryBoxes.videos, {'v1': '{"a":1}'});
    await (await backend()).putAll(EntryBoxes.videoFormats, {'v1': '[40]'});

    final again = await backend();
    expect(await again.loadAll(EntryBoxes.videos), {'v1': '{"a":1}'});
    expect(await again.loadAll(EntryBoxes.videoFormats), {'v1': '[40]'});
    expect(await again.loadAll(EntryBoxes.channelDetails), isEmpty);
  });

  test('entries can be deleted, and a box cleared', () async {
    final store = await backend();
    await store.putAll(EntryBoxes.videos, {'a': '1', 'b': '2', 'c': '3'});

    await store.deleteAll(EntryBoxes.videos, ['a']);
    expect((await store.loadAll(EntryBoxes.videos)).keys, {'b', 'c'});

    await store.clear(EntryBoxes.videos);
    expect(await store.loadAll(EntryBoxes.videos), isEmpty);
  });

  test('images are kept and read back after reopening', () async {
    await (await backend()).writeImage('pic', Uint8List.fromList([1, 2, 3]));

    expect(await (await backend()).readImage('pic'), [1, 2, 3]);
    expect(await (await backend()).readImage('missing'), isNull);
  });

  test('past the cap, the least recently shown images go first', () async {
    final store = await backend();
    for (final key in ['a', 'b', 'c']) {
      time = time.add(const Duration(minutes: 1));
      await store.writeImage(key, bytes(10));
    }
    time = time.add(const Duration(minutes: 1));
    await store.readImage('a');

    time = time.add(const Duration(minutes: 1));
    await store.writeImage('d', bytes(10));

    expect(await store.readImage('a'), isNotNull);
    expect(await store.readImage('d'), isNotNull);
    expect(await store.readImage('b'), isNull);
    expect(await store.readImage('c'), isNull);
  });

  test('the image just written is kept, even bigger than the trim', () async {
    final store = await backend();
    for (final key in ['a', 'b', 'c']) {
      time = time.add(const Duration(minutes: 1));
      await store.writeImage(key, bytes(10));
    }

    time = time.add(const Duration(minutes: 1));
    await store.writeImage('big', bytes(25));

    expect(await store.readImage('big'), isNotNull);
    for (final key in ['a', 'b', 'c']) {
      expect(await store.readImage(key), isNull);
    }
  });

  test('the size kept is remembered after reopening', () async {
    final first = await backend();
    for (final key in ['a', 'b', 'c']) {
      time = time.add(const Duration(minutes: 1));
      await first.writeImage(key, bytes(10));
    }

    final again = await backend();
    time = time.add(const Duration(minutes: 1));
    await again.writeImage('d', bytes(10));

    expect(await again.readImage('a'), isNull);
  });

  test('clearing images keeps entries', () async {
    final store = await backend();
    await store.putAll(EntryBoxes.videos, {'v1': '1'});
    await store.writeImage('pic', bytes(5));

    await store.clearImages();

    expect(await store.readImage('pic'), isNull);
    expect(await store.loadAll(EntryBoxes.videos), {'v1': '1'});
  });
}
