import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:squadron/squadron.dart';

import 'entry_store.dart';
import 'image_bytes_cache.dart';
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
  _mockImages = MemoryImageBytesCache();
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
