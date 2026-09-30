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
