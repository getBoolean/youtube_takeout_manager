import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';

import 'storage_backend.dart';
import 'storage_keys.dart';

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

  /// The images, opened on the first image call: opening them reads the
  /// whole file, which entries shouldn't wait for.
  Future<_Images>? _imagesOpened;
  final _boxes = <String, Future<Box<String>>>{};

  HiveBackend._({
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
    return HiveBackend._(
      capBytes: capBytes,
      trimToBytes: trimToBytes,
      touchEvery: touchEvery,
      now: now ?? DateTime.now,
    );
  }

  Future<_Images> _openImages() => _imagesOpened ??= () async {
    final images = await Hive.openLazyBox<Uint8List>(imageBox);
    final index = await Hive.openBox<String>(imageIndexBox);
    var total = 0;
    for (final use in index.values) {
      total += _ImageUse.parse(use).bytes;
    }
    return _Images(images, index, total);
  }();

  Future<Box<String>> _box(String name) =>
      _boxes[name] ??= Hive.openBox<String>(name);

  /// Marks a key kept as its digest, its value holding the key itself.
  static const _longKey = '#long:';

  /// Where [key] is kept: as it is, or, when too long for hive (or looking
  /// like a digest), under its digest.
  static String _hiveKey(String key) =>
      keyFits(key) && !key.startsWith(_longKey)
      ? key
      : '$_longKey${keyDigest(key)}';

  @override
  Future<Map<String, String>> loadAll(String box) async {
    final entries = <String, String>{};
    for (final MapEntry(:key, :value) in (await _box(box)).toMap().entries) {
      if ('$key'.startsWith(_longKey)) {
        final [String original, String kept] = (jsonDecode(value) as List)
            .cast<String>();
        entries[original] = kept;
      } else {
        entries['$key'] = value;
      }
    }
    return entries;
  }

  @override
  Future<void> putAll(String box, Map<String, String> entries) async =>
      (await _box(box)).putAll({
        for (final MapEntry(:key, :value) in entries.entries)
          _hiveKey(key): _hiveKey(key) == key
              ? value
              : jsonEncode([key, value]),
      });

  @override
  Future<void> deleteAll(String box, List<String> keys) async =>
      (await _box(box)).deleteAll(keys.map(_hiveKey));

  @override
  Future<void> clear(String box) async {
    await (await _box(box)).clear();
  }

  @override
  Future<Uint8List?> readImage(String key) async {
    final store = await _openImages();
    final bytes = await store.images.get(key);
    if (bytes == null) return null;
    final now = _now();
    final use = _ImageUse.parse(store.index.get(key) ?? '');
    if (now.difference(use.lastShown) >= touchEvery) {
      await store.index.put(key, _ImageUse(bytes.length, now).toString());
    }
    return bytes;
  }

  @override
  Future<void> writeImage(String key, Uint8List bytes) async {
    final store = await _openImages();
    final old = _ImageUse.parse(store.index.get(key) ?? '');
    await store.images.put(key, bytes);
    await store.index.put(key, _ImageUse(bytes.length, _now()).toString());
    store.bytes += bytes.length - old.bytes;
    if (store.bytes > capBytes) await _trim(store, keep: key);
  }

  /// Deletes the least recently shown images, never [keep], until
  /// [trimToBytes] is left or nothing else is.
  Future<void> _trim(_Images store, {required String keep}) async {
    final uses = [
      for (final MapEntry(:key, :value) in store.index.toMap().entries)
        if (key != keep) ('$key', _ImageUse.parse(value)),
    ]..sort((a, b) => a.$2.lastShown.compareTo(b.$2.lastShown));
    final gone = <String>[];
    for (final (key, use) in uses) {
      if (store.bytes <= trimToBytes) break;
      gone.add(key);
      store.bytes -= use.bytes;
    }
    await store.images.deleteAll(gone);
    await store.index.deleteAll(gone);
  }

  @override
  Future<void> clearImages() async {
    final store = await _openImages();
    await store.images.clear();
    await store.index.clear();
    store.bytes = 0;
  }

  @override
  Future<void> close() async {
    _boxes.clear();
    _imagesOpened = null;
    await Hive.close();
  }
}

/// The cached images, their index of sizes and last-shown times (as
/// `bytes:millis`), and how many bytes they take.
class _Images {
  final LazyBox<Uint8List> images;
  final Box<String> index;
  int bytes;

  _Images(this.images, this.index, this.bytes);
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
