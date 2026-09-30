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

/// Runs calls on a storage worker it starts on first use. An operation
/// that fails is the caller's to handle, on the same worker. A worker that
/// died is closed and replaced once, and every call under way when it died
/// runs again on the new one; dying again is passed on, not retried
/// forever. A start that fails is tried again on the next call.
class WorkerStorage {
  final Future<StorageService> Function() _start;
  final bool Function(StorageService service) _isDead;
  Future<StorageService>? _service;

  /// Raised when a dead worker is replaced, so a call that failed on it
  /// knows to run on the replacement rather than replace it again.
  var _generation = 0;
  var _restarted = false;

  WorkerStorage(this._start, {bool Function(StorageService service)? isDead})
    : _isDead = isDead ?? _workerDied;

  /// Whether [service]'s worker thread is gone.
  static bool _workerDied(StorageService service) => switch (service) {
    final Worker worker => worker.isStopped || !worker.isConnected,
    _ => false,
  };

  Future<T> run<T>(Future<T> Function(StorageService storage) call) async {
    final generation = _generation;
    final service = await _current();
    try {
      return await call(service);
    } on SquadronException {
      if (!_isDead(service)) rethrow;
      if (generation == _generation) {
        if (_restarted) rethrow;
        _restarted = true;
        _generation++;
        _service = null;
        await _retire(service);
      }
      return call(await _current());
    }
  }

  /// The worker, started when there's none, or when the last start failed.
  Future<StorageService> _current() {
    if (_service case final service?) return service;
    late final Future<StorageService> started;
    started = _start().onError<Object>((error, stackTrace) {
      if (identical(_service, started)) _service = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
    return _service = started;
  }

  Future<void> stop() async {
    final service = _service;
    _service = null;
    if (service == null) return;
    try {
      await _retire(await service);
    } on Object {
      // It never started.
    }
  }

  /// Closes [service]'s storage, releasing its files for a replacement,
  /// when it still answers, then stops its thread.
  static Future<void> _retire(StorageService service) async {
    try {
      await service.close().timeout(const Duration(seconds: 2));
    } on Object {
      // Already gone.
    }
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
