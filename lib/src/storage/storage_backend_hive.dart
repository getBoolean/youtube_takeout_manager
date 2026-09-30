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
