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
