# Phase 1: Storage worker, hive_ce, image cache — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the bulk caches out of shared preferences into per-entry storage run by a background worker (hive_ce on native, IndexedDB on web), add a device image cache for pictures and thumbnails, and make Clear cache clear only images.

**Architecture:**

- **The storage worker.** A squadron service, `StorageService`, runs in a background isolate on native and a Web Worker on web.
  - It owns a `StorageBackend`: hive_ce on native, IndexedDB on web.
- **The main-isolate side.**
  - The app talks to storage through `EntryStore` (boxes of string entries) and `ImageBytesCache` (image bytes).
  - `WorkerStorage` starts the worker, runs the one-time migration from shared preferences, and replaces a failed worker once.
- **Repositories.** Each keeps its public methods but stores entries through `EntryBox`/`EntrySet`, which write only what changed.
- **Tests.** All tests use an in-memory store through `setMockStorage`, reset for every test by `test/flutter_test_config.dart`.

**Tech Stack:** Flutter 3.47, Riverpod 3 codegen, squadron 7 + squadron_builder 9 (codegen), hive_ce 2, package:web IndexedDB, package:http.

**Spec:** `docs/superpowers/specs/2026-09-30-categories-v2-design.md` (sections: Workers, Storage, Image cache). This is plan 1 of 5; later phases get their own plans after this one lands.

## Global Constraints

**Git and packages:**
- Commit directly on `main`. Never add `Co-Authored-By` trailers. Commit subjects are plain sentences in the repo's style.
- Add packages only with `flutter pub add` (`flutter pub add squadron hive_ce`, `flutter pub add dev:squadron_builder`). Never hand-write versions in `pubspec.yaml`.

**Worker code:**
- Code the storage worker imports must never import `package:flutter/...` or plugins. That covers `storage_service.dart`, `storage_backend*.dart`, `entry_store.dart` and `idb_transaction.dart`. On the web it runs in a Web Worker compiled with `dart compile js`. On native it runs in a background isolate.
- Compiled workers (`web/workers/`) are build output. Never commit them, since no opaque binaries go in git.

**Tests:**
- Behaviour tests only: no exact-copy assertions, no goldens. Saves are tested by round trip.
- Providers under `lib/src/storage/` count as repositories (`test/src/architecture/provider_graph_test.dart`), so they may only use other repositories.

**Commands:**
- After changing annotated code: `dart run build_runner build -d`.
- Before every commit:
  - `dart format lib test tool`
  - `flutter analyze`
  - `flutter test`
  - `dart test -p chrome test_browser` (web storage)
- Run the app with `--dart-define-from-file=.env`.

**Values from the spec:**
- The image cache caps at 250 MB and trims to 200 MB.
- Clear cache clears only images.
- Web images use the browser's cache.
- A failed worker is restarted once, and a second failure is passed on.

## Review Focus

1. **A launch killed partway through the migration:** the blob stays in shared preferences, the next launch finishes the job, and nothing is lost or doubled. Task 5 tests a store that fails on write.
2. **A repository that saves before it ever loaded,** such as a fresh store writing first: it must replace the box, not leave stale entries behind. Task 1: "saving before loading replaces what the box held".
3. **The worker failing once,** such as a hive file error: the next call runs on a fresh worker. A second failure surfaces as an error, not a hang. Task 5: `WorkerStorage` tests.
4. **The image cache over its cap while a new picture is written:** the new picture always survives, and the least recently shown go first. Task 2: eviction tests, including an image bigger than the trim target.
5. **A picture download failing, or the device cache failing to read:** the picture loads from the network or shows its placeholder, and a failed download is never cached. Task 7: `CachedNetworkImage` tests.

---

### Task 1: Packages, `EntryStore`, `EntryBox`

**Files:**
- Modify: `pubspec.yaml` (through `flutter pub add` only)
- Create: `lib/src/storage/entry_store.dart`
- Create: `lib/src/storage/entry_box.dart`
- Test: `test/src/storage/entry_box_test.dart`

**Interfaces:**
- Produces: `abstract final class EntryBoxes` (box-name constants and `all`), `abstract interface class EntryStore { Future<Map<String, String>> loadAll(String box); Future<void> putAll(String box, Map<String, String> entries); Future<void> deleteAll(String box, List<String> keys); Future<void> clear(String box); }`, `class MemoryEntryStore implements EntryStore { MemoryEntryStore([Map<String, Map<String, String>>? boxes]); final Map<String, Map<String, String>> boxes; }`, `class EntryBox<T extends Object> { EntryBox(EntryStore store, String name, {required Object? Function(T value) encode, required T Function(Object? json) decode}); Future<Map<String, T>> load(); Future<void> save(Map<String, T> values); Future<void> clear(); }`, `class EntrySet { EntrySet(EntryStore store, String name); Future<Set<String>> load(); Future<void> save(Set<String> keys); Future<void> clear(); }`.

- [ ] **Step 1: Add the packages**

Run:
```bash
flutter pub add squadron hive_ce
flutter pub add dev:squadron_builder
```
Expected: `pubspec.yaml` lists `squadron` and `hive_ce` under dependencies and `squadron_builder` under dev_dependencies; `flutter pub get` succeeds.

- [ ] **Step 2: Write the failing tests**

Create `test/src/storage/entry_box_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';

/// Keeps entries in memory, recording each write.
class _Recording extends MemoryEntryStore {
  final puts = <Map<String, String>>[];
  final deletes = <List<String>>[];

  @override
  Future<void> putAll(String box, Map<String, String> entries) {
    puts.add({...entries});
    return super.putAll(box, entries);
  }

  @override
  Future<void> deleteAll(String box, List<String> keys) {
    deletes.add([...keys]);
    return super.deleteAll(box, keys);
  }
}

class _Item {
  final int n;

  const _Item(this.n);
}

EntryBox<_Item> _items(EntryStore store) => EntryBox(
  store,
  'items',
  encode: (item) => item.n,
  decode: (json) => _Item(json! as int),
);

void main() {
  test('values saved are loaded back', () async {
    final store = MemoryEntryStore();
    await _items(store).save({'a': const _Item(1), 'b': const _Item(2)});

    final loaded = await _items(store).load();
    expect({for (final e in loaded.entries) e.key: e.value.n}, {'a': 1, 'b': 2});
  });

  test('saving writes only the entries that changed', () async {
    final store = _Recording();
    await _items(store).save({'a': const _Item(1), 'b': const _Item(2)});
    final box = _items(store);
    final loaded = await box.load();
    store.puts.clear();

    await box.save({...loaded, 'b': const _Item(3), 'c': const _Item(4)});

    expect(store.puts, [
      {'b': '3', 'c': '4'},
    ]);
    expect(store.deletes, isEmpty);
  });

  test('saving deletes the entries no longer there', () async {
    final store = _Recording();
    await _items(store).save({'a': const _Item(1), 'b': const _Item(2)});
    final box = _items(store);
    final loaded = await box.load();

    await box.save({'a': loaded['a']!});

    expect(store.deletes, [
      ['b'],
    ]);
    expect((await _items(store).load()).keys, ['a']);
  });

  test('an entry that cannot be read is skipped, keeping the rest', () async {
    final store = MemoryEntryStore({
      'items': {'a': '1', 'b': '"nonsense"'},
    });

    expect((await _items(store).load()).keys, ['a']);
  });

  test('saving before loading replaces what the box held', () async {
    final store = MemoryEntryStore({
      'items': {'old': '9'},
    });

    await _items(store).save({'a': const _Item(1)});

    expect(await store.loadAll('items'), {'a': '1'});
  });

  test('clearing empties the box', () async {
    final store = MemoryEntryStore();
    final box = _items(store);
    await box.save({'a': const _Item(1)});

    await box.clear();

    expect(await store.loadAll('items'), isEmpty);
  });

  test('a set keeps what is added and removed', () async {
    final store = _Recording();
    await EntrySet(store, 'ids').save({'a', 'b'});
    final ids = EntrySet(store, 'ids');
    await ids.load();
    store.puts.clear();

    await ids.save({'b', 'c'});

    expect(store.puts.single.keys, ['c']);
    expect(store.deletes.single, ['a']);
    expect(await EntrySet(store, 'ids').load(), {'b', 'c'});
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/src/storage/entry_box_test.dart`
Expected: FAIL at compile time — `entry_box.dart` and `entry_store.dart` don't exist.

- [ ] **Step 4: Write `entry_store.dart`**

Create `lib/src/storage/entry_store.dart` (pure Dart: the storage worker imports it):

```dart
/// The boxes bulk data is kept in, one entry per video or channel.
abstract final class EntryBoxes {
  static const videos = 'videos';
  static const videosNotFound = 'videos_not_found';
  static const videoFormats = 'video_formats';
  static const videoFormatsNotFound = 'video_formats_not_found';
  static const channelPictures = 'channel_pictures';
  static const channelPicturesNotFound = 'channel_pictures_not_found';
  static const channelDetails = 'channel_details';
  static const channelCategories = 'channel_categories';
  static const customSubCategories = 'custom_sub_categories';

  /// Every box of entries, for storage that must create them up front.
  static const all = [
    videos,
    videosNotFound,
    videoFormats,
    videoFormatsNotFound,
    channelPictures,
    channelPicturesNotFound,
    channelDetails,
    channelCategories,
    customSubCategories,
  ];
}

/// Keeps bulk data as string entries in named boxes, each entry written on
/// its own, so saving a few never rewrites the rest.
abstract interface class EntryStore {
  /// Every entry of [box], by key; none for a box never written.
  Future<Map<String, String>> loadAll(String box);

  /// Writes [entries] into [box], replacing any with the same keys.
  Future<void> putAll(String box, Map<String, String> entries);

  Future<void> deleteAll(String box, List<String> keys);

  Future<void> clear(String box);
}

/// An [EntryStore] in memory over [boxes], which it shares, so stores made
/// over the same boxes see each other's writes: for tests.
class MemoryEntryStore implements EntryStore {
  final Map<String, Map<String, String>> boxes;

  MemoryEntryStore([Map<String, Map<String, String>>? boxes])
    : boxes = boxes ?? {};

  @override
  Future<Map<String, String>> loadAll(String box) async => {...?boxes[box]};

  @override
  Future<void> putAll(String box, Map<String, String> entries) async =>
      boxes.putIfAbsent(box, () => {}).addAll(entries);

  @override
  Future<void> deleteAll(String box, List<String> keys) async {
    final entries = boxes[box];
    if (entries == null) return;
    for (final key in keys) {
      entries.remove(key);
    }
  }

  @override
  Future<void> clear(String box) async => boxes.remove(box);
}
```

- [ ] **Step 5: Write `entry_box.dart`**

Create `lib/src/storage/entry_box.dart`:

```dart
import 'dart:convert';

import 'entry_store.dart';

/// One box of an [EntryStore] as a map of [T]s, each value kept as JSON on
/// its own. Saving writes only the values that changed since the last load
/// or save (compared by identity, as stores replace only what changed), and
/// deletes the ones gone.
class EntryBox<T extends Object> {
  final EntryStore _store;
  final String name;
  final Object? Function(T value) _encode;
  final T Function(Object? json) _decode;

  /// What the box holds, as last loaded or saved; null until then.
  Map<String, T>? _saved;

  EntryBox(
    this._store,
    this.name, {
    required Object? Function(T value) encode,
    required T Function(Object? json) decode,
  }) : _encode = encode,
       _decode = decode;

  /// Every value, skipping entries that can't be read.
  Future<Map<String, T>> load() async {
    final values = <String, T>{};
    for (final MapEntry(:key, :value) in (await _store.loadAll(name)).entries) {
      try {
        values[key] = _decode(jsonDecode(value));
      } on Object {
        // Unreadable: left out, as a blob's bad entries always were.
      }
    }
    _saved = Map.of(values);
    return values;
  }

  /// Makes the box hold exactly [values].
  Future<void> save(Map<String, T> values) async {
    final saved = _saved;
    if (saved == null) {
      // Never loaded: what the box holds is unknown, so it's replaced.
      await _store.clear(name);
      await _store.putAll(name, {
        for (final MapEntry(:key, :value) in values.entries)
          key: jsonEncode(_encode(value)),
      });
    } else {
      final changed = {
        for (final MapEntry(:key, :value) in values.entries)
          if (!identical(saved[key], value)) key: jsonEncode(_encode(value)),
      };
      final gone = [
        for (final key in saved.keys)
          if (!values.containsKey(key)) key,
      ];
      if (changed.isNotEmpty) await _store.putAll(name, changed);
      if (gone.isNotEmpty) await _store.deleteAll(name, gone);
    }
    _saved = Map.of(values);
  }

  Future<void> clear() async {
    await _store.clear(name);
    _saved = {};
  }
}

/// One box of an [EntryStore] as a set of keys, such as IDs YouTube no
/// longer has. Saving writes only what was added or removed.
class EntrySet {
  final EntryStore _store;
  final String name;
  Set<String>? _saved;

  EntrySet(this._store, this.name);

  Future<Set<String>> load() async {
    final keys = (await _store.loadAll(name)).keys.toSet();
    _saved = {...keys};
    return keys;
  }

  Future<void> save(Set<String> keys) async {
    final saved = _saved;
    if (saved == null) {
      await _store.clear(name);
      await _store.putAll(name, {for (final key in keys) key: '1'});
    } else {
      final added = keys.difference(saved);
      final gone = saved.difference(keys);
      if (added.isNotEmpty) {
        await _store.putAll(name, {for (final key in added) key: '1'});
      }
      if (gone.isNotEmpty) await _store.deleteAll(name, gone.toList());
    }
    _saved = {...keys};
  }

  Future<void> clear() async {
    await _store.clear(name);
    _saved = {};
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/src/storage/entry_box_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 7: Commit**

```bash
dart format lib test
git add pubspec.yaml pubspec.lock lib/src/storage/entry_store.dart lib/src/storage/entry_box.dart test/src/storage/entry_box_test.dart
git commit -m "Keep bulk data as entries that are written only when they change"
```

---

### Task 2: The hive backend

**Files:**
- Create: `lib/src/storage/storage_backend.dart`
- Create: `lib/src/storage/storage_backend_stub.dart`
- Create: `lib/src/storage/storage_backend_hive.dart`
- Test: `test/src/storage/storage_backend_hive_test.dart`

**Interfaces:**
- Consumes: `EntryBoxes` (Task 1).
- Produces: `abstract interface class StorageBackend { loadAll; putAll; deleteAll; clear; Future<Uint8List?> readImage(String key); Future<void> writeImage(String key, Uint8List bytes); Future<void> clearImages(); Future<void> close(); }` (same entry signatures as `EntryStore`), `Future<StorageBackend> openStorageBackend(String? directory)` (conditionally exported from `storage_backend.dart`), `class HiveBackend implements StorageBackend { static Future<HiveBackend> open(String directory, {int capBytes, int trimToBytes, Duration touchEvery, DateTime Function()? now}); }`.

- [ ] **Step 1: Write the failing tests**

Create `test/src/storage/storage_backend_hive_test.dart`:

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/src/storage/storage_backend_hive_test.dart`
Expected: FAIL at compile time — `storage_backend_hive.dart` doesn't exist.

- [ ] **Step 3: Write the backend interface and stub**

Create `lib/src/storage/storage_backend.dart`:

```dart
import 'dart:typed_data';

export 'storage_backend_stub.dart'
    if (dart.library.io) 'storage_backend_hive.dart'
    if (dart.library.js_interop) 'storage_backend_idb.dart'
    show openStorageBackend;

/// Where the storage worker keeps entries and images: hive files on native
/// platforms, IndexedDB on the web.
abstract interface class StorageBackend {
  Future<Map<String, String>> loadAll(String box);

  Future<void> putAll(String box, Map<String, String> entries);

  Future<void> deleteAll(String box, List<String> keys);

  Future<void> clear(String box);

  /// An image's bytes, or null when it isn't kept.
  Future<Uint8List?> readImage(String key);

  Future<void> writeImage(String key, Uint8List bytes);

  Future<void> clearImages();

  Future<void> close();
}
```

Create `lib/src/storage/storage_backend_stub.dart`:

```dart
import 'storage_backend.dart';

/// No storage where there are neither files nor IndexedDB.
Future<StorageBackend> openStorageBackend(String? directory) =>
    throw UnsupportedError('No storage on this platform.');
```

- [ ] **Step 4: Write the hive backend**

Create `lib/src/storage/storage_backend_hive.dart`:

```dart
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';

import 'storage_backend.dart';

/// Native storage, in hive files under [directory].
Future<StorageBackend> openStorageBackend(String? directory) {
  if (directory == null) throw ArgumentError.notNull('directory');
  return HiveBackend.open(directory);
}

/// Entries and images in hive files. Images are capped: past [capBytes], the
/// least recently shown are deleted until [trimToBytes] is left, never the
/// one just written.
class HiveBackend implements StorageBackend {
  static const imageBox = 'images';
  static const imageIndexBox = 'image_index';

  final int capBytes;
  final int trimToBytes;

  /// How long an image's last-shown time may lag, so showing one doesn't
  /// write every time.
  final Duration touchEvery;
  final DateTime Function() _now;
  final LazyBox<Uint8List> _images;

  /// Each image's size and when it was last shown, as `bytes:millis`.
  final Box<String> _index;
  int _imageBytes;
  final _boxes = <String, Future<Box<String>>>{};

  HiveBackend._(
    this._images,
    this._index,
    this._imageBytes, {
    required this.capBytes,
    required this.trimToBytes,
    required this.touchEvery,
    required DateTime Function() now,
  }) : _now = now;

  static Future<HiveBackend> open(
    String directory, {
    int capBytes = 250 * 1024 * 1024,
    int trimToBytes = 200 * 1024 * 1024,
    Duration touchEvery = const Duration(hours: 1),
    DateTime Function()? now,
  }) async {
    Hive.init(directory);
    final images = await Hive.openLazyBox<Uint8List>(imageBox);
    final index = await Hive.openBox<String>(imageIndexBox);
    var total = 0;
    for (final use in index.values) {
      total += _ImageUse.parse(use).bytes;
    }
    return HiveBackend._(
      images,
      index,
      total,
      capBytes: capBytes,
      trimToBytes: trimToBytes,
      touchEvery: touchEvery,
      now: now ?? DateTime.now,
    );
  }

  Future<Box<String>> _box(String name) =>
      _boxes[name] ??= Hive.openBox<String>(name);

  @override
  Future<Map<String, String>> loadAll(String box) async => {
    for (final MapEntry(:key, :value) in (await _box(box)).toMap().entries)
      '$key': value,
  };

  @override
  Future<void> putAll(String box, Map<String, String> entries) async =>
      (await _box(box)).putAll(entries);

  @override
  Future<void> deleteAll(String box, List<String> keys) async =>
      (await _box(box)).deleteAll(keys);

  @override
  Future<void> clear(String box) async {
    await (await _box(box)).clear();
  }

  @override
  Future<Uint8List?> readImage(String key) async {
    final bytes = await _images.get(key);
    if (bytes == null) return null;
    final now = _now();
    final use = _ImageUse.parse(_index.get(key) ?? '');
    if (now.difference(use.lastShown) >= touchEvery) {
      await _index.put(key, _ImageUse(bytes.length, now).toString());
    }
    return bytes;
  }

  @override
  Future<void> writeImage(String key, Uint8List bytes) async {
    final old = _ImageUse.parse(_index.get(key) ?? '');
    await _images.put(key, bytes);
    await _index.put(key, _ImageUse(bytes.length, _now()).toString());
    _imageBytes += bytes.length - old.bytes;
    if (_imageBytes > capBytes) await _trim(keep: key);
  }

  /// Deletes the least recently shown images, never [keep], until
  /// [trimToBytes] is left or nothing else is.
  Future<void> _trim({required String keep}) async {
    final uses = [
      for (final MapEntry(:key, :value) in _index.toMap().entries)
        if (key != keep) ('$key', _ImageUse.parse(value)),
    ]..sort((a, b) => a.$2.lastShown.compareTo(b.$2.lastShown));
    final gone = <String>[];
    for (final (key, use) in uses) {
      if (_imageBytes <= trimToBytes) break;
      gone.add(key);
      _imageBytes -= use.bytes;
    }
    await _images.deleteAll(gone);
    await _index.deleteAll(gone);
  }

  @override
  Future<void> clearImages() async {
    await _images.clear();
    await _index.clear();
    _imageBytes = 0;
  }

  @override
  Future<void> close() async {
    _boxes.clear();
    await Hive.close();
  }
}

/// How big an image is and when it was last shown.
class _ImageUse {
  final int bytes;
  final DateTime lastShown;

  const _ImageUse(this.bytes, this.lastShown);

  /// Unreadable or missing, it's nothing, shown long ago.
  static _ImageUse parse(String value) {
    final parts = value.split(':');
    return _ImageUse(
      parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0,
      DateTime.fromMillisecondsSinceEpoch(
        parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
    );
  }

  @override
  String toString() => '$bytes:${lastShown.millisecondsSinceEpoch}';
}
```

`storage_backend.dart` also names `storage_backend_idb.dart`, which Task 3 creates. To compile natively before Task 3, create that file now with only this content, and Task 3 replaces it:

```dart
import 'storage_backend.dart';

Future<StorageBackend> openStorageBackend(String? directory) =>
    throw UnsupportedError('Written in Task 3.');
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/src/storage/storage_backend_hive_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 6: Commit**

```bash
dart format lib test
git add lib/src/storage/storage_backend.dart lib/src/storage/storage_backend_stub.dart lib/src/storage/storage_backend_hive.dart lib/src/storage/storage_backend_idb.dart test/src/storage/storage_backend_hive_test.dart
git commit -m "Keep entries and capped images in hive files"
```

---

### Task 3: The IndexedDB backend (web)

**Files:**
- Modify: `lib/src/storage/storage_backend_idb.dart` (replace the Task 2 placeholder)
- Test: `test_browser/storage/storage_backend_idb_test.dart`

**Interfaces:**
- Consumes: `StorageBackend`, `EntryBoxes`, `transactionDone` from `lib/src/storage/idb_transaction.dart`.
- Produces: `class IdbBackend implements StorageBackend { static const databaseName = 'app_entries'; static const version = 1; static Future<IdbBackend> open(); }`. Images aren't kept on the web: `readImage` and `writeImage` throw `UnsupportedError`, and `clearImages` does nothing.

- [ ] **Step 1: Write the failing browser test**

Create `test_browser/storage/storage_backend_idb_test.dart`:

```dart
@TestOn('browser')
library;

import 'package:test/test.dart';

import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_backend_idb.dart';

import '../web_databases.dart';

void main() {
  setUp(() => deleteDatabases([IdbBackend.databaseName]));

  test('entries are kept by box and read back after reopening', () async {
    final first = await IdbBackend.open();
    await first.putAll(EntryBoxes.videos, {'v1': '{"a":1}', 'v2': '2'});
    await first.putAll(EntryBoxes.channelDetails, {'UCa': '{}'});
    await first.close();

    final again = await IdbBackend.open();
    expect(await again.loadAll(EntryBoxes.videos), {'v1': '{"a":1}', 'v2': '2'});
    expect(await again.loadAll(EntryBoxes.channelDetails), {'UCa': '{}'});
    expect(await again.loadAll(EntryBoxes.videoFormats), isEmpty);
    await again.close();
  });

  test('entries can be deleted, and a box cleared', () async {
    final store = await IdbBackend.open();
    await store.putAll(EntryBoxes.videos, {'a': '1', 'b': '2'});

    await store.deleteAll(EntryBoxes.videos, ['a']);
    expect(await store.loadAll(EntryBoxes.videos), {'b': '2'});

    await store.clear(EntryBoxes.videos);
    expect(await store.loadAll(EntryBoxes.videos), isEmpty);
    await store.close();
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dart test -p chrome test_browser/storage/storage_backend_idb_test.dart`
Expected: FAIL at compile time — `IdbBackend` isn't defined.

- [ ] **Step 3: Write the IndexedDB backend**

Replace `lib/src/storage/storage_backend_idb.dart` with:

```dart
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'entry_store.dart';
import 'idb_transaction.dart';
import 'storage_backend.dart';

/// Web storage, in IndexedDB.
Future<StorageBackend> openStorageBackend(String? directory) =>
    IdbBackend.open();

/// Entries in IndexedDB, one object store per box. Works in a page or a
/// Web Worker, which has no `window`. Images are left to the browser's
/// cache.
class IdbBackend implements StorageBackend {
  static const databaseName = 'app_entries';

  /// Raised when [EntryBoxes.all] gains a box, so it's created.
  static const version = 1;

  final web.IDBDatabase _db;

  IdbBackend._(this._db);

  static web.IDBFactory get _factory =>
      globalContext.getProperty<web.IDBFactory>('indexedDB'.toJS);

  static Future<IdbBackend> open() {
    final done = Completer<IdbBackend>();
    final request = _factory.open(databaseName, version);
    request.onupgradeneeded = (web.IDBVersionChangeEvent _) {
      final db = request.result as web.IDBDatabase;
      for (final box in EntryBoxes.all) {
        if (!db.objectStoreNames.contains(box)) db.createObjectStore(box);
      }
    }.toJS;
    request.onsuccess = (web.Event _) {
      done.complete(IdbBackend._(request.result as web.IDBDatabase));
    }.toJS;
    request.onerror = (web.Event _) {
      done.completeError(
        StateError('Could not open IndexedDB: ${request.error?.message}'),
      );
    }.toJS;
    return done.future;
  }

  @override
  Future<Map<String, String>> loadAll(String box) {
    final done = Completer<Map<String, String>>();
    final entries = <String, String>{};
    final request = _db
        .transaction(box.toJS, 'readonly')
        .objectStore(box)
        .openCursor();
    request.onsuccess = (web.Event _) {
      final cursor = request.result as web.IDBCursorWithValue?;
      if (cursor == null) {
        done.complete(entries);
        return;
      }
      entries[(cursor.key as JSString).toDart] =
          (cursor.value as JSString).toDart;
      cursor.continue_();
    }.toJS;
    request.onerror = (web.Event _) {
      done.completeError(
        StateError('Could not read $box: ${request.error?.message}'),
      );
    }.toJS;
    return done.future;
  }

  @override
  Future<void> putAll(String box, Map<String, String> entries) {
    final txn = _db.transaction(box.toJS, 'readwrite');
    final store = txn.objectStore(box);
    for (final MapEntry(:key, :value) in entries.entries) {
      store.put(value.toJS, key.toJS);
    }
    return transactionDone(txn, 'write $box');
  }

  @override
  Future<void> deleteAll(String box, List<String> keys) {
    final txn = _db.transaction(box.toJS, 'readwrite');
    final store = txn.objectStore(box);
    for (final key in keys) {
      store.delete(key.toJS);
    }
    return transactionDone(txn, 'delete from $box');
  }

  @override
  Future<void> clear(String box) {
    final txn = _db.transaction(box.toJS, 'readwrite');
    txn.objectStore(box).clear();
    return transactionDone(txn, 'clear $box');
  }

  @override
  Future<Uint8List?> readImage(String key) =>
      throw UnsupportedError('On the web, the browser caches images.');

  @override
  Future<void> writeImage(String key, Uint8List bytes) =>
      throw UnsupportedError('On the web, the browser caches images.');

  @override
  Future<void> clearImages() async {}

  @override
  Future<void> close() async => _db.close();
}
```

If `package:web` names the cursor method differently from `continue_`, the analyzer says so. Use its name for `IDBCursor.continue()`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `dart test -p chrome test_browser/storage/storage_backend_idb_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
dart format lib test_browser
git add lib/src/storage/storage_backend_idb.dart test_browser/storage/storage_backend_idb_test.dart
git commit -m "Keep entries in IndexedDB on the web, from a page or a worker"
```

---

### Task 4: The storage worker (squadron), its web build, CI

**Files:**
- Create: `lib/src/storage/storage_service.dart`
- Generated (by build_runner, committed like the repo's other `.g.dart` files): `lib/src/storage/storage_service.worker.g.dart`, `storage_service.activator.g.dart`, `storage_service.vm.g.dart`, `storage_service.web.g.dart`, `storage_service.stub.g.dart`
- Create: `tool/compile_workers.dart`
- Modify: `.gitignore` (add `/web/workers/`)
- Modify: `.github/workflows/build.yml` (compile workers before the web build)
- Modify: `README.md` (web development note)
- Test: `test/src/storage/storage_service_test.dart`

**Interfaces:**
- Consumes: `EntryStore`, `EntryBoxes` (Task 1); `StorageBackend`, `openStorageBackend` (Tasks 2 and 3).
- Produces: `base class StorageService implements EntryStore` with squadron methods `Future<void> open(String? directory)`, the four `EntryStore` methods, `Future<Uint8List?> readImage(String key)`, `Future<void> writeImage(String key, Uint8List bytes)`, `Future<void> clearImages()`, `Future<void> close()`. The generated `StorageServiceWorker` implements `StorageService`, and `stop()` ends its thread.

- [ ] **Step 1: Write the failing tests**

Create `test/src/storage/storage_service_test.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_service.dart';

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('storage'));
  tearDown(() => dir.delete(recursive: true));

  test('keeps entries and images once opened', () async {
    final storage = StorageService();
    addTearDown(storage.close);
    await storage.open(dir.path);

    await storage.putAll(EntryBoxes.videos, {'v1': '1'});
    await storage.writeImage('pic', Uint8List.fromList([7]));

    expect(await storage.loadAll(EntryBoxes.videos), {'v1': '1'});
    expect(await storage.readImage('pic'), [7]);
  });

  test('asked before it is opened, it says so', () async {
    expect(StorageService().loadAll(EntryBoxes.videos), throwsStateError);
  });

  test('runs in a worker of its own', () async {
    final worker = StorageServiceWorker();
    addTearDown(() async {
      await worker.close();
      worker.stop();
    });

    await worker.open(dir.path);
    await worker.putAll(EntryBoxes.videos, {'v1': '1'});

    expect(await worker.loadAll(EntryBoxes.videos), {'v1': '1'});
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/src/storage/storage_service_test.dart`
Expected: FAIL at compile time — `storage_service.dart` doesn't exist.

- [ ] **Step 3: Write the service**

Create `lib/src/storage/storage_service.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:squadron/squadron.dart';

import 'entry_store.dart';
import 'storage_backend.dart';
import 'storage_service.activator.g.dart';

part 'storage_service.worker.g.dart';

/// Keeps the app's bulk data, entries in boxes and cached images, off the
/// UI thread: run as a worker, an isolate on native and a Web Worker on
/// the web. Nothing it imports may import Flutter: on the web it's compiled
/// on its own.
@SquadronService(
  baseUrl: '~/workers',
  targetPlatform: TargetPlatform.vm | TargetPlatform.web,
)
base class StorageService implements EntryStore {
  StorageBackend? _backend;

  StorageBackend get _open =>
      _backend ?? (throw StateError('Storage was not opened.'));

  /// Opens storage in [directory] on native platforms, or IndexedDB on the
  /// web (where [directory] is null).
  @SquadronMethod()
  Future<void> open(String? directory) async {
    _backend ??= await openStorageBackend(directory);
  }

  @override
  @SquadronMethod()
  Future<Map<String, String>> loadAll(String box) async => _open.loadAll(box);

  @override
  @SquadronMethod()
  Future<void> putAll(String box, Map<String, String> entries) async =>
      _open.putAll(box, entries);

  @override
  @SquadronMethod()
  Future<void> deleteAll(String box, List<String> keys) async =>
      _open.deleteAll(box, keys);

  @override
  @SquadronMethod()
  Future<void> clear(String box) async => _open.clear(box);

  @SquadronMethod()
  Future<Uint8List?> readImage(String key) async => _open.readImage(key);

  @SquadronMethod()
  Future<void> writeImage(String key, Uint8List bytes) async =>
      _open.writeImage(key, bytes);

  @SquadronMethod()
  Future<void> clearImages() async => _open.clearImages();

  @SquadronMethod()
  Future<void> close() async {
    await _backend?.close();
    _backend = null;
  }
}
```

Each method is `async` so `_open`'s `StateError` becomes a failed future rather than a synchronous throw, which the second test relies on.

- [ ] **Step 4: Generate the worker**

Run: `dart run build_runner build -d`
Expected: `storage_service.worker.g.dart`, `storage_service.activator.g.dart`, `storage_service.vm.g.dart`, `storage_service.web.g.dart` and `storage_service.stub.g.dart` appear next to `storage_service.dart`. `StorageServiceWorker` is defined in the worker part.

If the generator says it needs a marshaler for `Uint8List`, do this:
- Annotate the `bytes` parameter and the `readImage` return type with squadron's `@IdentityMarshaler()`. On native an isolate copies typed data as-is, and the web never calls the image methods.
- Regenerate.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/src/storage/storage_service_test.dart`
Expected: PASS, 3 tests. The third spawns a real isolate.

Run: `flutter analyze`
Expected: no issues. If the analyzer reports lints only inside generated squadron files, add `- "**/*.worker.g.dart"`, `- "**/*.activator.g.dart"`, `- "**/*.vm.g.dart"`, `- "**/*.web.g.dart"` and `- "**/*.stub.g.dart"` under `analyzer: exclude:` in `analysis_options.yaml`, and rerun.

- [ ] **Step 6: Write the worker compile tool**

Create `tool/compile_workers.dart`:

```dart
import 'dart:io';

/// Compiles every squadron web worker entry point (`lib/**/*.web.g.dart`)
/// to JavaScript in `web/workers`, where the web app loads them. Run it
/// before `flutter build web` or `flutter run -d chrome`, and again after
/// changing worker code.
Future<void> main() async {
  final entries = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.web.g.dart'));
  await Directory('web/workers').create(recursive: true);
  for (final entry in entries) {
    final name = entry.uri.pathSegments.last;
    stdout.writeln('Compiling $name');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      entry.path,
      '-o',
      'web/workers/$name.js',
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) exit(result.exitCode);
  }
}
```

Add to `.gitignore`, under `# Flutter/Dart/Pub related`:

```
# Web workers compiled by tool/compile_workers.dart
/web/workers/
```

Run: `dart run tool/compile_workers.dart`
Expected: `web/workers/storage_service.web.g.dart.js` exists. `git status` shows no files under `web/workers/`.

- [ ] **Step 7: Compile the workers in CI's web build**

In `.github/workflows/build.yml`, in the `build` job, add this step between the `subosito/flutter-action@v2` step and `- name: Build`:

```yaml
      - name: Compile web workers
        if: matrix.platform == 'web'
        run: |
          flutter pub get
          dart run tool/compile_workers.dart
```

`release.yml` reuses `build.yml` (`uses: ./.github/workflows/build.yml`), so releases get the step too. `test/src/config/release_keys_test.dart` still passes, since no `--dart-define-from-file` was added.

- [ ] **Step 8: Note it for web development**

In `README.md`, in the section on running the app, after the `flutter run` command for Chrome, add:

```markdown
The web app runs its storage in a Web Worker. Compile the workers once, and again after changing their code:

```bash
dart run tool/compile_workers.dart
```
```

- [ ] **Step 9: Run the checks and commit**

Run: `dart format lib test tool && flutter analyze && flutter test test/src/storage test/src/config`
Expected: no issues; all pass.

```bash
git add lib/src/storage/storage_service.dart lib/src/storage/storage_service.*.g.dart tool/compile_workers.dart .gitignore .github/workflows/build.yml README.md test/src/storage/storage_service_test.dart analysis_options.yaml
git commit -m "Run storage in a worker of its own, an isolate or a Web Worker"
```

---

### Task 5: Storage providers, restart-once, test storage, migration

**Files:**
- Create: `lib/src/storage/storage_migration.dart`
- Create: `lib/src/storage/storage_providers.dart`
- Create: `test/flutter_test_config.dart`
- Test: `test/src/storage/storage_migration_test.dart`
- Test: `test/src/storage/worker_storage_test.dart`

**Interfaces:**
- Consumes: `StorageService`, `StorageServiceWorker` (Task 4); `EntryStore`, `MemoryEntryStore`, `EntryBoxes` (Task 1); `KvStorageService`, `kvStorageServiceProvider` (`lib/src/storage/kv_storage_service.dart`).
- Produces:
  - `enum LegacyShape { jsonMap, stringList, jsonList }`
  - `typedef LegacyBlob = ({String key, String box, LegacyShape shape})`
  - `const List<LegacyBlob> legacyBlobs`
  - `Future<void> migrateLegacyBlobs(KvStorageService kv, EntryStore store, {List<LegacyBlob> blobs = legacyBlobs})`
  - `class WorkerStorage { WorkerStorage(Future<StorageService> Function() start); Future<T> run<T>(Future<T> Function(StorageService storage) call); Future<void> stop(); }`
  - `class WorkerEntryStore implements EntryStore { WorkerEntryStore(WorkerStorage storage); }`
  - `Future<String?> storageDirectory()`
  - `workerStorageProvider` (`WorkerStorage`, keepAlive) and `entryStoreProvider` (`EntryStore`, keepAlive)
  - `@visibleForTesting void setMockStorage({Map<String, Map<String, String>> entries = const {}})`
  - `Map<String, Map<String, String>>? get mockStorageEntries` (what tests seeded, for assertions)

- [ ] **Step 1: Write the failing migration tests**

Create `test/src/storage/storage_migration_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import 'package:youtube_takeout_manager/src/storage/storage_migration.dart';

/// Fails every write, as a full disk would.
class _Failing extends MemoryEntryStore {
  @override
  Future<void> putAll(String box, Map<String, String> entries) =>
      throw StateError('disk full');
}

/// Keeps only the first entry of each write.
class _Lossy extends MemoryEntryStore {
  @override
  Future<void> putAll(String box, Map<String, String> entries) =>
      super.putAll(box, Map.fromEntries(entries.entries.take(1)));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({
    'flutter.cached_video_metadata': jsonEncode({
      'v1': {'videoId': 'v1', 'channelId': 'UCa'},
      'v2': {'videoId': 'v2', 'channelId': 'UCb'},
    }),
    'flutter.video_not_found_ids': ['gone1', 'gone2'],
    'flutter.channel_thumbnails_not_found': jsonEncode(['UCx']),
    'flutter.search_scope': 'everything',
  }));

  test('moves each blob into its box, an entry per item, and removes it',
      () async {
    final kv = KvStorageService();
    final store = MemoryEntryStore();

    await migrateLegacyBlobs(kv, store);

    final videos = await store.loadAll(EntryBoxes.videos);
    expect(videos.keys, {'v1', 'v2'});
    expect(jsonDecode(videos['v1']!), {'videoId': 'v1', 'channelId': 'UCa'});
    expect((await store.loadAll(EntryBoxes.videosNotFound)).keys, {
      'gone1',
      'gone2',
    });
    expect(
      (await store.loadAll(EntryBoxes.channelPicturesNotFound)).keys,
      {'UCx'},
    );
    expect(await kv.getString('cached_video_metadata'), isNull);
    expect(await kv.getStringList('video_not_found_ids'), isNull);
    // Small settings stay where they are.
    expect(await kv.getString('search_scope'), 'everything');
  });

  test('a write that fails leaves the blob for the next launch', () async {
    final kv = KvStorageService();

    await migrateLegacyBlobs(kv, _Failing());

    expect(await kv.getString('cached_video_metadata'), isNotNull);

    final store = MemoryEntryStore();
    await migrateLegacyBlobs(kv, store);
    expect((await store.loadAll(EntryBoxes.videos)).keys, {'v1', 'v2'});
    expect(await kv.getString('cached_video_metadata'), isNull);
  });

  test('entries that do not read back the same leave the blob', () async {
    final kv = KvStorageService();

    await migrateLegacyBlobs(kv, _Lossy());

    expect(await kv.getString('cached_video_metadata'), isNotNull);
  });

  test('once done, running again changes nothing', () async {
    final kv = KvStorageService();
    final store = MemoryEntryStore();
    await migrateLegacyBlobs(kv, store);
    final before = {
      for (final box in EntryBoxes.all) box: await store.loadAll(box),
    };

    await migrateLegacyBlobs(kv, store);

    expect({
      for (final box in EntryBoxes.all) box: await store.loadAll(box),
    }, before);
  });
}
```

- [ ] **Step 2: Write the failing `WorkerStorage` tests**

Create `test/src/storage/worker_storage_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:squadron/squadron.dart';

import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import 'package:youtube_takeout_manager/src/storage/storage_service.dart';

/// Storage whose first [failures] calls fail as a crashed worker's do.
final class _Flaky extends StorageService {
  int failures;

  _Flaky(this.failures);

  @override
  Future<Map<String, String>> loadAll(String box) async {
    if (failures-- > 0) throw WorkerException('crashed');
    return {'k': 'v'};
  }
}

void main() {
  test('a worker that fails is replaced once, and the call goes through',
      () async {
    var started = 0;
    final storage = WorkerStorage(() async => _Flaky(started++ == 0 ? 1 : 0));

    expect(await storage.run((s) => s.loadAll('box')), {'k': 'v'});
    expect(started, 2);
  });

  test('failing again is passed on, not retried forever', () async {
    var started = 0;
    final storage = WorkerStorage(() async {
      started++;
      return _Flaky(1);
    });

    await expectLater(
      storage.run((s) => s.loadAll('box')),
      throwsA(isA<WorkerException>()),
    );
    expect(started, 2);
  });

  test('the worker is started once, on first use', () async {
    var started = 0;
    final storage = WorkerStorage(() async {
      started++;
      return _Flaky(0);
    });
    expect(started, 0);

    await storage.run((s) => s.loadAll('a'));
    await storage.run((s) => s.loadAll('b'));

    expect(started, 1);
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/src/storage/storage_migration_test.dart test/src/storage/worker_storage_test.dart`
Expected: FAIL at compile time — `storage_migration.dart` and `storage_providers.dart` don't exist.

- [ ] **Step 4: Write the migration**

Create `lib/src/storage/storage_migration.dart`:

```dart
import 'dart:convert';

import 'entry_store.dart';
import 'kv_storage_service.dart';

/// How a blob kept whole in key-value storage was shaped.
enum LegacyShape {
  /// A JSON object of items by key.
  jsonMap,

  /// A string list of IDs.
  stringList,

  /// A JSON array of IDs, kept as a string.
  jsonList,
}

/// A blob from before entries: its key-value key, the box its items move
/// to, and its shape.
typedef LegacyBlob = ({String key, String box, LegacyShape shape});

/// Every blob that moves into a box.
const legacyBlobs = <LegacyBlob>[
  (
    key: 'cached_video_metadata',
    box: EntryBoxes.videos,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'video_not_found_ids',
    box: EntryBoxes.videosNotFound,
    shape: LegacyShape.stringList,
  ),
  (
    key: 'video_formats',
    box: EntryBoxes.videoFormats,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'video_formats_not_found',
    box: EntryBoxes.videoFormatsNotFound,
    shape: LegacyShape.stringList,
  ),
  (
    key: 'cached_channel_thumbnails',
    box: EntryBoxes.channelPictures,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'channel_thumbnails_not_found',
    box: EntryBoxes.channelPicturesNotFound,
    shape: LegacyShape.jsonList,
  ),
  (
    key: 'channel_details',
    box: EntryBoxes.channelDetails,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'channel_categories',
    box: EntryBoxes.channelCategories,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'custom_category_children',
    box: EntryBoxes.customSubCategories,
    shape: LegacyShape.jsonMap,
  ),
];

/// Moves each of [blobs] from [kv] into its box of [store], an entry per
/// item. A blob is removed only once its entries read back the same; a
/// failure anywhere leaves it for the next launch. Never throws.
Future<void> migrateLegacyBlobs(
  KvStorageService kv,
  EntryStore store, {
  List<LegacyBlob> blobs = legacyBlobs,
}) async {
  for (final blob in blobs) {
    try {
      final entries = await _read(kv, blob);
      if (entries == null) continue;
      await store.putAll(blob.box, entries);
      final back = await store.loadAll(blob.box);
      if (entries.entries.every((e) => back[e.key] == e.value)) {
        await kv.remove(blob.key);
      }
    } on Object {
      // Left for the next launch.
    }
  }
}

/// [blob]'s items as entries (each value as JSON, IDs as `1`), or null
/// when there's no such blob.
Future<Map<String, String>?> _read(KvStorageService kv, LegacyBlob blob) async {
  switch (blob.shape) {
    case LegacyShape.stringList:
      final ids = await kv.getStringList(blob.key);
      return ids == null ? null : {for (final id in ids) id: '1'};
    case LegacyShape.jsonList:
      final json = await kv.getString(blob.key);
      if (json == null) return null;
      return {
        for (final id in (jsonDecode(json) as List<dynamic>).whereType<String>())
          id: '1',
      };
    case LegacyShape.jsonMap:
      final json = await kv.getString(blob.key);
      if (json == null) return null;
      return {
        for (final MapEntry(:key, :value)
            in (jsonDecode(json) as Map<String, dynamic>).entries)
          key: jsonEncode(value),
      };
  }
}
```

- [ ] **Step 5: Write the providers**

Create `lib/src/storage/storage_providers.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:squadron/squadron.dart';

import 'entry_store.dart';
import 'kv_storage_service.dart';
import 'storage_migration.dart';
import 'storage_service.dart';

part 'storage_providers.g.dart';

/// Runs calls on a storage worker it starts on first use. A worker that
/// fails is replaced once, the call running again on the new one; a second
/// failure is passed on, not retried forever.
class WorkerStorage {
  final Future<StorageService> Function() _start;
  Future<StorageService>? _service;
  var _restarted = false;

  WorkerStorage(this._start);

  Future<T> run<T>(Future<T> Function(StorageService storage) call) async {
    final service = await (_service ??= _start());
    try {
      return await call(service);
    } on SquadronException {
      if (_restarted) rethrow;
      _restarted = true;
      _stopWorker(service);
      final fresh = await (_service = _start());
      return call(fresh);
    }
  }

  Future<void> stop() async {
    final service = _service;
    _service = null;
    if (service != null) _stopWorker(await service);
  }

  static void _stopWorker(StorageService service) {
    if (service case final Worker worker) worker.stop();
  }
}

/// An [EntryStore] whose calls run on the storage worker.
class WorkerEntryStore implements EntryStore {
  final WorkerStorage _storage;

  WorkerEntryStore(this._storage);

  @override
  Future<Map<String, String>> loadAll(String box) =>
      _storage.run((s) => s.loadAll(box));

  @override
  Future<void> putAll(String box, Map<String, String> entries) =>
      _storage.run((s) => s.putAll(box, entries));

  @override
  Future<void> deleteAll(String box, List<String> keys) =>
      _storage.run((s) => s.deleteAll(box, keys));

  @override
  Future<void> clear(String box) => _storage.run((s) => s.clear(box));
}

/// Where native storage keeps its files; none on the web, which uses
/// IndexedDB.
Future<String?> storageDirectory() async => kIsWeb
    ? null
    : p.join((await getApplicationSupportDirectory()).path, 'storage');

Map<String, Map<String, String>>? _mockEntries;

/// Tests: storage made from now on is in memory, starting from [entries]
/// by box, and shared by every store until set again, as
/// `SharedPreferences.setMockInitialValues` does. `flutter_test_config.dart`
/// resets it before every test.
@visibleForTesting
void setMockStorage({Map<String, Map<String, String>> entries = const {}}) {
  _mockEntries = {
    for (final MapEntry(:key, :value) in entries.entries) key: {...value},
  };
}

/// What the test storage holds now, by box; null outside tests.
@visibleForTesting
Map<String, Map<String, String>>? get mockStorageEntries => _mockEntries;

/// The storage worker, started on first use. Its first start moves the
/// blobs kept in key-value storage into boxes, once.
@Riverpod(keepAlive: true)
WorkerStorage workerStorage(Ref ref) {
  final kv = ref.watch(kvStorageServiceProvider);
  Future<void>? migrated;
  final storage = WorkerStorage(() async {
    final worker = StorageServiceWorker();
    await worker.open(await storageDirectory());
    await (migrated ??= migrateLegacyBlobs(kv, worker));
    return worker;
  });
  ref.onDispose(storage.stop);
  return storage;
}

/// Where bulk data is kept: the storage worker, or memory in tests.
@Riverpod(keepAlive: true)
EntryStore entryStore(Ref ref) {
  if (_mockEntries case final entries?) return MemoryEntryStore(entries);
  return WorkerEntryStore(ref.watch(workerStorageProvider));
}
```

Create `test/flutter_test_config.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';

/// Runs before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // The app keeps bulk data in a worker; tests keep it in memory, fresh
  // for each test, as SharedPreferences' mock does.
  setUp(setMockStorage);
  await testMain();
}
```

- [ ] **Step 6: Generate, run the tests to verify they pass**

Run: `dart run build_runner build -d && flutter test test/src/storage test/src/architecture`
Expected: PASS, including the provider-graph test.

- [ ] **Step 7: Commit**

```bash
dart format lib test
git add lib/src/storage/storage_migration.dart lib/src/storage/storage_providers.dart lib/src/storage/storage_providers.g.dart test/flutter_test_config.dart test/src/storage/storage_migration_test.dart test/src/storage/worker_storage_test.dart
git commit -m "Move blobs kept whole into boxes once, and replace a failed worker"
```

---

### Task 6: The cache repositories keep entries

**Files:**
- Modify: `lib/src/features/videos/data/video_cache_repository.dart`
- Modify: `lib/src/features/videos/data/video_format_cache_repository.dart`
- Modify: `lib/src/features/channels/data/channel_cache_repository.dart`
- Modify: `lib/src/features/channels/data/channel_details_repository.dart`
- Modify: `lib/src/features/categories/data/channel_category_repository.dart`
- Modify tests: `test/src/features/videos/data/video_format_cache_repository_test.dart`, `test/src/features/videos/data/video_thumbnail_test.dart`, `test/src/features/categories/data/channel_category_repository_test.dart`, `test/src/features/channels/application/channel_thumbnails_test.dart`

**Interfaces:**
- Consumes: `EntryBox`, `EntrySet`, `EntryBoxes`, `MemoryEntryStore` (Task 1); `entryStoreProvider`, `setMockStorage` (Task 5).
- Produces: each repository's constructor takes an `EntryStore`, and its provider watches `entryStoreProvider`. Their public methods keep their names and types, so their callers don't change.

- [ ] **Step 1: Update the repository tests to the new storage (failing)**

In `test/src/features/videos/data/video_format_cache_repository_test.dart`:
- Replace the imports of `shared_preferences` and `kv_storage_service` with `package:youtube_takeout_manager/src/storage/entry_store.dart`.
- Replace `setUp(() => SharedPreferences.setMockInitialValues({}));` with `late Map<String, Map<String, String>> boxes; setUp(() => boxes = {});`
- Replace `VideoFormatCacheRepository(KvStorageService())` with `VideoFormatCacheRepository(MemoryEntryStore(boxes))`.
- Replace the unreadable-entry test's seed with:

```dart
    boxes[EntryBoxes.videoFormats] = {'a': '[40,2]', 'b': '"nonsense"'};
```

In `test/src/features/videos/data/video_thumbnail_test.dart`, replace the two lines

```dart
    SharedPreferences.setMockInitialValues({});
    final cache = VideoCacheRepository(KvStorageService());
```

with

```dart
    final cache = VideoCacheRepository(MemoryEntryStore());
```

Then fix the imports: drop `shared_preferences` and `kv_storage_service` if now unused, and add `entry_store.dart`.

In `test/src/features/categories/data/channel_category_repository_test.dart`:
- Use a shared `MemoryEntryStore` the same way: `late MemoryEntryStore store; setUp(() => store = MemoryEntryStore());` and `ChannelCategoryRepository(store)`.
- Replace the corrupting test body with:

```dart
    await repository().saveCategories({'UCa': category});
    store.boxes[EntryBoxes.channelCategories]!['UCbad'] = '"nonsense"';

    expect((await repository().loadCategories()).keys, ['UCa']);
```

In `test/src/features/channels/application/channel_thumbnails_test.dart`, replace each seed of the form

```dart
    SharedPreferences.setMockInitialValues({
      'flutter.cached_channel_thumbnails': '{"UCold":"https://saved/UCold"}',
    });
```

with

```dart
    setMockStorage(
      entries: {
        EntryBoxes.channelPictures: {'UCold': '"https://saved/UCold"'},
      },
    );
```

- Import `package:youtube_takeout_manager/src/storage/entry_store.dart` and `package:youtube_takeout_manager/src/storage/storage_providers.dart`.
- Keep the file's other `SharedPreferences.setMockInitialValues({})` calls: other settings still use it.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/src/features/videos/data test/src/features/categories/data test/src/features/channels/application/channel_thumbnails_test.dart`
Expected: FAIL. The repository constructors still take `KvStorageService`, and the thumbnails tests find no seeded picture.

- [ ] **Step 3: Rewrite the repositories**

Replace the body of `lib/src/features/videos/data/video_cache_repository.dart` after its imports (keeping its doc comments' intent) with:

```dart
@Riverpod(keepAlive: true)
VideoCacheRepository videoCacheRepository(Ref ref) =>
    VideoCacheRepository(ref.watch(entryStoreProvider));

class VideoCacheRepository {
  final EntryBox<Video> _videos;
  final EntrySet _notFound;

  VideoCacheRepository(EntryStore store)
    : _videos = EntryBox(
        store,
        EntryBoxes.videos,
        encode: (video) => video.toMap(),
        decode: (json) =>
            _upgraded(VideoMapper.fromMap(json! as Map<String, dynamic>)),
      ),
      _notFound = EntrySet(store, EntryBoxes.videosNotFound);

  Future<Map<String, Video>> loadCachedVideos() => _videos.load();

  /// Videos cached before `medium` thumbnails were fetched have the 120x90
  /// `default` one. YouTube serves `medium` next to it as `mqdefault`, the
  /// URL the API now returns.
  static final _smallThumbnail = RegExp(r'/default(_live)?\.jpg$');

  static Video _upgraded(Video video) {
    final thumbnail = video.thumbnailUrl;
    final upgraded = thumbnail?.replaceFirstMapped(
      _smallThumbnail,
      (match) => '/mqdefault${match[1] ?? ''}.jpg',
    );
    return upgraded == thumbnail
        ? video
        : video.copyWith(thumbnailUrl: upgraded);
  }

  Future<void> saveVideos(Map<String, Video> videos) => _videos.save(videos);

  Future<Set<String>> loadNotFoundIds() => _notFound.load();

  Future<void> saveNotFoundIds(Set<String> ids) => _notFound.save(ids);

  Future<void> clearCache() async {
    await _videos.clear();
    await _notFound.clear();
  }
}
```

Its imports become:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import '../domain/video.dart';

part 'video_cache_repository.g.dart';
```

Replace `lib/src/features/videos/data/video_format_cache_repository.dart`'s class and provider with:

```dart
@Riverpod(keepAlive: true)
VideoFormatCacheRepository videoFormatCacheRepository(Ref ref) =>
    VideoFormatCacheRepository(ref.watch(entryStoreProvider));

/// Keeps the watched videos' lengths and shapes on this device, and the
/// videos YouTube no longer has, so neither is asked for again.
class VideoFormatCacheRepository {
  final EntryBox<VideoFormat> _formats;
  final EntrySet _notFound;

  VideoFormatCacheRepository(EntryStore store)
    : _formats = EntryBox(
        store,
        EntryBoxes.videoFormats,
        encode: (format) => format.toJson(),
        decode: (json) => VideoFormat.fromJson(json! as List<dynamic>),
      ),
      _notFound = EntrySet(store, EntryBoxes.videoFormatsNotFound);

  /// Entries that can't be read are skipped, keeping the rest.
  Future<Map<String, VideoFormat>> loadFormats() => _formats.load();

  Future<void> saveFormats(Map<String, VideoFormat> formats) =>
      _formats.save(formats);

  Future<Set<String>> loadNotFoundIds() => _notFound.load();

  Future<void> saveNotFoundIds(Set<String> ids) => _notFound.save(ids);

  Future<void> clear() async {
    await _formats.clear();
    await _notFound.clear();
  }
}
```

Its imports: `riverpod_annotation`, `entry_box.dart`, `entry_store.dart`, `storage_providers.dart`, `../domain/video_format.dart`, `part 'video_format_cache_repository.g.dart';`. Drop `dart:convert` and `kv_storage_service.dart`.

Replace `lib/src/features/channels/data/channel_cache_repository.dart`'s class and provider with:

```dart
@Riverpod(keepAlive: true)
ChannelCacheRepository channelCacheRepository(Ref ref) =>
    ChannelCacheRepository(ref.watch(entryStoreProvider));

class ChannelCacheRepository {
  final EntryBox<String> _pictures;
  final EntrySet _notFound;

  ChannelCacheRepository(EntryStore store)
    : _pictures = EntryBox(
        store,
        EntryBoxes.channelPictures,
        encode: (url) => url,
        decode: (json) => json! as String,
      ),
      _notFound = EntrySet(store, EntryBoxes.channelPicturesNotFound);

  Future<Map<String, String>> loadCachedThumbnails() => _pictures.load();

  Future<void> saveThumbnails(Map<String, String> thumbnails) =>
      _pictures.save(thumbnails);

  /// Channels YouTube had no picture for, e.g. since deleted, so they
  /// aren't asked for again.
  Future<Set<String>> loadNotFoundIds() => _notFound.load();

  Future<void> saveNotFoundIds(Set<String> ids) => _notFound.save(ids);

  /// Forgets the pictures and the channels that had none.
  Future<void> clearThumbnails() async {
    await _pictures.clear();
    await _notFound.clear();
  }
}
```

Replace `lib/src/features/channels/data/channel_details_repository.dart`'s class and provider with:

```dart
@Riverpod(keepAlive: true)
ChannelDetailsRepository channelDetailsRepository(Ref ref) =>
    ChannelDetailsRepository(ref.watch(entryStoreProvider));

class ChannelDetailsRepository {
  final EntryBox<ChannelDetails> _details;

  ChannelDetailsRepository(EntryStore store)
    : _details = EntryBox(
        store,
        EntryBoxes.channelDetails,
        encode: (details) => details.toJson(),
        decode: (json) =>
            ChannelDetails.fromJson(json! as Map<String, dynamic>),
      );

  /// Entries that can't be read are skipped, keeping the rest.
  Future<Map<String, ChannelDetails>> load() => _details.load();

  Future<void> save(Map<String, ChannelDetails> details) =>
      _details.save(details);

  Future<void> clear() => _details.clear();
}
```

Replace `lib/src/features/categories/data/channel_category_repository.dart`'s class and provider with:

```dart
@Riverpod(keepAlive: true)
ChannelCategoryRepository channelCategoryRepository(Ref ref) =>
    ChannelCategoryRepository(ref.watch(entryStoreProvider));

class ChannelCategoryRepository {
  final EntryBox<ChannelCategory> _categories;
  final EntryBox<List<String>> _custom;

  ChannelCategoryRepository(EntryStore store)
    : _categories = EntryBox(
        store,
        EntryBoxes.channelCategories,
        encode: (category) => category.toMap(),
        decode: (json) =>
            ChannelCategoryMapper.fromMap(json! as Map<String, dynamic>),
      ),
      _custom = EntryBox(
        store,
        EntryBoxes.customSubCategories,
        encode: (children) => children,
        decode: (json) => (json! as List<dynamic>).cast<String>(),
      );

  /// Categories that can't be read are skipped, keeping the rest.
  Future<Map<String, ChannelCategory>> loadCategories() => _categories.load();

  Future<void> saveCategories(Map<String, ChannelCategory> categories) =>
      _categories.save(categories);

  /// The sub-categories AI made, by category.
  Future<Map<String, List<String>>> loadCustomChildren() => _custom.load();

  Future<void> saveCustomChildren(Map<String, List<String>> children) =>
      _custom.save(children);
}
```

In each file, replace the `kv_storage_service.dart` import with `entry_box.dart`, `entry_store.dart` and `storage_providers.dart` (all `package:youtube_takeout_manager/src/storage/...`). Drop the old key constants and `dart:convert` where unused.

- [ ] **Step 4: Generate and run the tests**

Run: `dart run build_runner build -d && flutter test test/src/features test/src/architecture`
Expected: PASS. If a test outside the four files above still seeds these caches through `SharedPreferences` (search `test/` for `cached_video_metadata`, `video_formats`, `cached_channel_thumbnails`, `channel_details`, `channel_categories`, `custom_category_children`), move its seed to `setMockStorage` the same way.

- [ ] **Step 5: Run the whole suite**

Run: `flutter test`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
dart format lib test
git add lib/src/features test
git commit -m "Keep video, channel and category caches as entries in the storage worker"
```

---

### Task 7: The device image cache

**Files:**
- Create: `lib/src/storage/image_bytes_cache.dart`
- Modify: `lib/src/storage/storage_providers.dart` (add `WorkerImageBytesCache`, `imageBytesCacheProvider`, mock images)
- Create: `lib/src/common_widgets/cached_network_image.dart`
- Modify: `lib/src/common_widgets/fade_in_picture.dart` (`NetworkPicture`)
- Modify: `lib/src/app.dart` (provide the cache)
- Test: `test/src/common_widgets/cached_network_image_test.dart`

**Interfaces:**
- Consumes: `WorkerStorage`, `_mockEntries`, `setMockStorage` (Task 5); `StorageService.readImage/writeImage/clearImages` (Task 4).
- Produces:
  - `abstract interface class ImageBytesCache { Future<Uint8List?> read(String key); Future<void> write(String key, Uint8List bytes); Future<void> clear(); }`
  - `class MemoryImageBytesCache implements ImageBytesCache { final Map<String, Uint8List> images; }`
  - `String imageCacheKey(String url)`
  - `imageBytesCacheProvider` (`ImageBytesCache?`, keepAlive; null on the web)
  - `class CachedNetworkImage extends ImageProvider<CachedNetworkImage> { const CachedNetworkImage(String url, ImageBytesCache cache, {http.Client? client}); }`
  - `class ImageBytesCacheScope extends InheritedWidget { const ImageBytesCacheScope({required ImageBytesCache? cache, required Widget child}); static ImageBytesCache? maybeOf(BuildContext context); }`

- [ ] **Step 1: Write the failing tests**

Create `test/src/common_widgets/cached_network_image_test.dart`:

```dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cached_network_image.dart';
import 'package:youtube_takeout_manager/src/common_widgets/fade_in_picture.dart';
import 'package:youtube_takeout_manager/src/storage/image_bytes_cache.dart';

const _url = 'https://i.ytimg.com/vi/abc/mqdefault.jpg';

/// A 1×1 PNG, drawn rather than kept as a binary.
Future<Uint8List> _png() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFFFF0000),
  );
  final image = await recorder.endRecording().toImage(1, 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// A cache whose reads fail, as a crashed worker's would.
class _Broken implements ImageBytesCache {
  @override
  Future<Uint8List?> read(String key) => throw StateError('gone');

  @override
  Future<void> write(String key, Uint8List bytes) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  late Uint8List png;
  late int requests;

  setUp(() => requests = 0);

  http.Client client({int status = 200}) => MockClient((_) async {
    requests++;
    return http.Response.bytes(status == 200 ? png : [], status);
  });

  Future<void> load(WidgetTester tester, ImageProvider image) async {
    await tester.runAsync(() async {
      final context = tester.element(find.byType(SizedBox));
      await precacheImage(image, context, onError: (_, _) {});
    });
  }

  Future<void> pumpHost(WidgetTester tester) async {
    png = (await tester.runAsync(_png))!;
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('a picture is downloaded once, then read from the device', (
    tester,
  ) async {
    await pumpHost(tester);
    final cache = MemoryImageBytesCache();

    await load(tester, CachedNetworkImage(_url, cache, client: client()));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    PaintingBinding.instance.imageCache.clear();
    await load(tester, CachedNetworkImage(_url, cache, client: client()));

    expect(requests, 1);
    expect(cache.images, hasLength(1));
  });

  testWidgets("a picture that fails to download isn't kept", (tester) async {
    await pumpHost(tester);
    final cache = MemoryImageBytesCache();

    await load(
      tester,
      CachedNetworkImage(_url, cache, client: client(status: 404)),
    );

    expect(cache.images, isEmpty);
  });

  testWidgets('a cache that fails to read falls back to the network', (
    tester,
  ) async {
    await pumpHost(tester);

    await load(tester, CachedNetworkImage(_url, _Broken(), client: client()));

    expect(requests, 1);
  });

  testWidgets('pictures under a cache scope go through the cache', (
    tester,
  ) async {
    await pumpHost(tester);
    final cache = MemoryImageBytesCache();
    await tester.pumpWidget(
      ImageBytesCacheScope(
        cache: cache,
        child: const MaterialApp(
          home: NetworkPicture(
            url: _url,
            placeholder: SizedBox(),
            width: 40,
            height: 40,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image)).image;
    expect(image, isA<ResizeImage>());
    expect((image as ResizeImage).imageProvider, isA<CachedNetworkImage>());
  });

  test('keys fit storage: short URLs as they are, long ones shortened', () {
    expect(imageCacheKey(_url), _url);
    final long = 'https://yt3.ggpht.com/${'x' * 400}';
    expect(imageCacheKey(long).length, lessThanOrEqualTo(255));
    expect(imageCacheKey(long), isNot(imageCacheKey('${long}y')));
  });
}
```

If `FadeInPicture` doesn't build an `Image` directly, find the `Image` via `find.descendant(of: find.byType(NetworkPicture), matching: find.byType(Image))`. The assertion only checks that the provider under the scope goes through the cache.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/src/common_widgets/cached_network_image_test.dart`
Expected: FAIL at compile time — `cached_network_image.dart` and `image_bytes_cache.dart` don't exist.

- [ ] **Step 3: Write the cache interface**

Create `lib/src/storage/image_bytes_cache.dart`:

```dart
import 'dart:typed_data';

/// Image bytes kept on the device, by [imageCacheKey].
abstract interface class ImageBytesCache {
  Future<Uint8List?> read(String key);

  Future<void> write(String key, Uint8List bytes);

  Future<void> clear();
}

/// An [ImageBytesCache] in memory: for tests.
class MemoryImageBytesCache implements ImageBytesCache {
  final images = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String key) async => images[key];

  @override
  Future<void> write(String key, Uint8List bytes) async => images[key] = bytes;

  @override
  Future<void> clear() async => images.clear();
}

/// The longest key storage takes.
const _maxKey = 255;

/// The key an image at [url] is kept under: the URL itself, or, past what
/// storage takes, its start and a hash of the whole.
String imageCacheKey(String url) {
  if (url.length <= _maxKey) return url;
  var hash = 0x811c9dc5;
  for (final unit in url.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return '${url.substring(0, 240)}~${hash.toRadixString(16)}';
}
```

The hash is only ever computed on native, since the web uses the browser's cache, so its 32-bit arithmetic is exact.

- [ ] **Step 4: Add the worker cache and its provider**

Append to `lib/src/storage/storage_providers.dart`, and import `image_bytes_cache.dart` and `dart:typed_data`:

```dart
/// An [ImageBytesCache] whose calls run on the storage worker.
class WorkerImageBytesCache implements ImageBytesCache {
  final WorkerStorage _storage;

  WorkerImageBytesCache(this._storage);

  @override
  Future<Uint8List?> read(String key) => _storage.run((s) => s.readImage(key));

  @override
  Future<void> write(String key, Uint8List bytes) =>
      _storage.run((s) => s.writeImage(key, bytes));

  @override
  Future<void> clear() => _storage.run((s) => s.clearImages());
}

MemoryImageBytesCache? _mockImages;

/// Where pictures and thumbnails are kept on the device: none on the web,
/// where the browser caches them.
@Riverpod(keepAlive: true)
ImageBytesCache? imageBytesCache(Ref ref) {
  if (kIsWeb) return null;
  if (_mockEntries != null) return _mockImages ??= MemoryImageBytesCache();
  return WorkerImageBytesCache(ref.watch(workerStorageProvider));
}
```

In `setMockStorage`, also reset the images by adding `_mockImages = MemoryImageBytesCache();` as its last line.

- [ ] **Step 5: Write the image provider and scope**

Create `lib/src/common_widgets/cached_network_image.dart`:

```dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:youtube_takeout_manager/src/storage/image_bytes_cache.dart';

/// The picture at [url], read from [cache] when kept there, else downloaded
/// and kept for next time. A cache that can't be read is skipped; a failed
/// download is never kept.
class CachedNetworkImage extends ImageProvider<CachedNetworkImage> {
  final String url;
  final ImageBytesCache cache;
  final http.Client? client;

  static final _client = http.Client();

  const CachedNetworkImage(this.url, this.cache, {this.client});

  @override
  Future<CachedNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CachedNetworkImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(decode),
    scale: 1,
    debugLabel: url,
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final key = imageCacheKey(url);
    Uint8List? bytes;
    try {
      bytes = await cache.read(key);
    } on Object {
      // Shown from the network instead.
    }
    if (bytes == null) {
      final uri = Uri.parse(url);
      final response = await (client ?? _client).get(uri);
      if (response.statusCode != 200) {
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: uri,
        );
      }
      bytes = response.bodyBytes;
      // Kept for next time; showing it doesn't wait.
      unawaited(cache.write(key, bytes).catchError((Object _) {}));
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is CachedNetworkImage &&
      other.url == url &&
      identical(other.cache, cache);

  @override
  int get hashCode => Object.hash(url, identityHashCode(cache));
}

/// Gives the pictures below it [cache] to keep their bytes in; none leaves
/// them to the network (and the browser's cache).
class ImageBytesCacheScope extends InheritedWidget {
  final ImageBytesCache? cache;

  const ImageBytesCacheScope({
    super.key,
    required this.cache,
    required super.child,
  });

  static ImageBytesCache? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ImageBytesCacheScope>()
      ?.cache;

  @override
  bool updateShouldNotify(ImageBytesCacheScope oldWidget) =>
      !identical(oldWidget.cache, cache);
}
```

- [ ] **Step 6: Use it for network pictures and provide it app-wide**

In `lib/src/common_widgets/fade_in_picture.dart`, add the import `import 'cached_network_image.dart';`. In `NetworkPicture.build`, replace

```dart
    final network = NetworkImage(
      url,
      webHtmlElementStrategy: htmlElementOnWeb
          ? WebHtmlElementStrategy.prefer
          : WebHtmlElementStrategy.never,
    );
```

with

```dart
    // Kept on the device where there's a cache; the web's browser keeps
    // its own.
    final cache = kIsWeb ? null : ImageBytesCacheScope.maybeOf(context);
    final ImageProvider network = cache == null
        ? NetworkImage(
            url,
            webHtmlElementStrategy: htmlElementOnWeb
                ? WebHtmlElementStrategy.prefer
                : WebHtmlElementStrategy.never,
          )
        : CachedNetworkImage(url, cache);
```

In `lib/src/app.dart`, import `package:youtube_takeout_manager/src/common_widgets/cached_network_image.dart` and `package:youtube_takeout_manager/src/storage/storage_providers.dart`. Add to `MaterialApp.router(...)`:

```dart
      builder: (context, child) => ImageBytesCacheScope(
        cache: ref.watch(imageBytesCacheProvider),
        child: child!,
      ),
```

- [ ] **Step 7: Generate, run the tests to verify they pass**

Run: `dart run build_runner build -d && flutter test test/src/common_widgets test/src/storage test/src/architecture test/src/narrow_width_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
dart format lib test
git add lib/src/storage/image_bytes_cache.dart lib/src/storage/storage_providers.dart lib/src/storage/storage_providers.g.dart lib/src/common_widgets/cached_network_image.dart lib/src/common_widgets/fade_in_picture.dart lib/src/app.dart test/src/common_widgets/cached_network_image_test.dart
git commit -m "Keep channel pictures and thumbnails on the device, capped"
```

---

### Task 8: Clear cache clears only images

**Files:**
- Modify: `lib/src/features/device_cache/application/device_cache_clearer.dart`
- Modify: `lib/src/features/device_cache/presentation/cache_section.dart`
- Modify: `lib/src/features/takeout/presentation/takeouts_dialog.dart:151` (no Cache section on the web)
- Modify: `test/src/features/device_cache/application/device_cache_clearer_test.dart` (rewrite)

**Interfaces:**
- Consumes: `imageBytesCacheProvider`, `setMockStorage`, `mockStorageEntries` (Tasks 5 and 7).
- Produces: `DeviceCacheClearer.clear()` clears the device image cache and the pictures held in memory, and nothing else.

- [ ] **Step 1: Rewrite the clearer's tests (failing)**

Replace `test/src/features/device_cache/application/device_cache_clearer_test.dart` with:

```dart
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/device_cache/application/device_cache_clearer.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final kept = {
    EntryBoxes.videos: {'v1': '{"videoId":"v1","channelId":"UCa"}'},
    EntryBoxes.videoFormats: {'v1': '[40,2]'},
    EntryBoxes.channelPictures: {'UCa': '"https://yt3.example/UCa"'},
    EntryBoxes.channelDetails: {'UCa': '{"topicUrls":[]}'},
    EntryBoxes.channelCategories: {'UCa': '{"decidedAt":"2026-09-30"}'},
  };

  ProviderContainer container() {
    setMockStorage(entries: kept);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('clears the pictures and thumbnails kept on the device', () async {
    final c = container();
    final images = c.read(imageBytesCacheProvider)!;
    await images.write('pic', Uint8List.fromList([1]));

    await c.read(deviceCacheClearerProvider.notifier).clear();

    expect(await images.read('pic'), isNull);
  });

  test('keeps video details, lengths and shapes, picture links, topics and '
      'categories', () async {
    final c = container();

    await c.read(deviceCacheClearerProvider.notifier).clear();

    expect(mockStorageEntries, kept);
  });

  test('forgets the pictures held in memory', () async {
    final c = container();
    final memory = PaintingBinding.instance.imageCache;
    memory.putIfAbsent(
      'held',
      () => OneFrameImageStreamCompleter(Future.any([])),
    );
    expect(memory.pendingImageCount + memory.currentSize, greaterThan(0));

    await c.read(deviceCacheClearerProvider.notifier).clear();

    expect(memory.pendingImageCount + memory.currentSize, 0);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/src/features/device_cache`
Expected: FAIL. The clearer still empties the other boxes (the "keeps" test fails) and never touches the image cache (the "clears" test fails).

- [ ] **Step 3: Rewrite the clearer**

Replace the body of `DeviceCacheClearer` in `lib/src/features/device_cache/application/device_cache_clearer.dart`, keeping `build()`, with:

```dart
  /// Clears the pictures and thumbnails kept on this device, and the ones
  /// held in memory, so they're downloaded again as they're shown.
  /// Everything else loaded from YouTube is kept: video details, lengths
  /// and shapes, picture links, topics and categories.
  Future<void> clear() async {
    await ref.read(imageBytesCacheProvider)?.clear();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }
```

Fix the imports. Add `package:flutter/painting.dart` and `package:youtube_takeout_manager/src/storage/storage_providers.dart`. Remove the imports of the video, channel and fetcher providers no longer used. Update the class doc comment to say it clears images only.

- [ ] **Step 4: Update the section and hide it on the web**

In `lib/src/features/device_cache/presentation/cache_section.dart`, set:

```dart
      description:
          'Channel pictures and video thumbnails are kept on this device, '
          'so they show at once and offline.',
```

```dart
      question:
          'Clear the pictures and thumbnails kept on this device? They '
          "download again as they're shown. Video details, channel topics "
          'and categories are kept.',
```

In `lib/src/features/takeout/presentation/takeouts_dialog.dart`, change `const CacheSection(),` to `if (!kIsWeb) const CacheSection(),`, since the web leaves pictures to the browser's cache. Import `package:flutter/foundation.dart` for `kIsWeb` if the file doesn't already.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/src/features/device_cache test/src/features/takeout test/src/narrow_width_test.dart`
Expected: PASS.

- [ ] **Step 6: Run everything**

Run: `dart format --set-exit-if-changed lib test tool && flutter analyze && flutter test && dart test -p chrome test_browser`
Expected: formatting clean, no analyzer issues, all tests pass.

Then run the app on Windows with `flutter run -d windows --dart-define-from-file=.env`, and check:
- History and channel pictures appear as before.
- The app's support folder (`getApplicationSupportDirectory()`) has a `storage` folder with the hive files.
- The shared-preferences blobs are gone after the first launch.
- A second launch shows pictures without re-downloading them.
- Clear cache leaves video titles and categories in place.

- [ ] **Step 7: Commit**

```bash
git add lib/src/features/device_cache lib/src/features/takeout/presentation/takeouts_dialog.dart test/src/features/device_cache
git commit -m "Clear only the pictures and thumbnails kept on the device"
```
