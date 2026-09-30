import 'dart:typed_data';

import 'storage_keys.dart';

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

/// The key an image at [url] is kept under: the URL itself, or, past what
/// storage takes, a digest of it.
String imageCacheKey(String url) =>
    keyFits(url) ? url : '#url:${keyDigest(url)}';
