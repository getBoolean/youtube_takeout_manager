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
