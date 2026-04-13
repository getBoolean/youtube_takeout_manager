import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'takeout_persistence_service.dart';

/// Web implementation: persists CSV data in IndexedDB.
class TakeoutPersistenceServiceImpl implements TakeoutPersistenceService {
  static const _dbName = 'takeout_csvs';
  static const _storeName = 'files';
  static const _version = 1;

  Future<web.IDBDatabase> _openDb() {
    final completer = Completer<web.IDBDatabase>();
    final request = web.window.self.indexedDB.open(_dbName, _version);

    request.onupgradeneeded = (web.IDBVersionChangeEvent event) {
      final db =
          (event.target as web.IDBOpenDBRequest).result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    }.toJS;

    request.onsuccess = (web.Event event) {
      completer.complete(request.result as web.IDBDatabase);
    }.toJS;

    request.onerror = (web.Event event) {
      completer.completeError(
        Exception('Failed to open IndexedDB: ${request.error?.message}'),
      );
    }.toJS;

    return completer.future;
  }

  @override
  Future<void> saveCsvs(Map<String, Uint8List> csvFiles) async {
    final db = await _openDb();
    try {
      // Clear existing data first
      await _clearStore(db);

      final txn = db.transaction(_storeName.toJS, 'readwrite');
      final store = txn.objectStore(_storeName);

      for (final entry in csvFiles.entries) {
        store.put(entry.value.toJS, entry.key.toJS);
      }

      final completer = Completer<void>();
      txn.oncomplete = (web.Event _) {
        completer.complete();
      }.toJS;
      txn.onerror = (web.Event _) {
        completer.completeError(
          Exception('Failed to save CSVs: ${txn.error?.message}'),
        );
      }.toJS;
      await completer.future;
    } finally {
      db.close();
    }
  }

  @override
  Future<Map<String, Uint8List>?> loadCsvs() async {
    final db = await _openDb();
    try {
      final txn = db.transaction(_storeName.toJS, 'readonly');
      final store = txn.objectStore(_storeName);

      // Get all keys
      final keysCompleter = Completer<List<String>>();
      final keysRequest = store.getAllKeys(null);
      keysRequest.onsuccess = (web.Event _) {
        final jsArray = keysRequest.result as JSArray;
        final keys = <String>[];
        for (var i = 0; i < jsArray.length; i++) {
          keys.add((jsArray[i] as JSString).toDart);
        }
        keysCompleter.complete(keys);
      }.toJS;
      keysRequest.onerror = (web.Event _) {
        keysCompleter.completeError(
          Exception('Failed to get keys: ${keysRequest.error?.message}'),
        );
      }.toJS;
      final keys = await keysCompleter.future;

      if (keys.isEmpty) return null;

      // Get all values
      final result = <String, Uint8List>{};
      for (final key in keys) {
        final getCompleter = Completer<Uint8List>();
        final txn2 = db.transaction(_storeName.toJS, 'readonly');
        final store2 = txn2.objectStore(_storeName);
        final getRequest = store2.get(key.toJS);
        getRequest.onsuccess = (web.Event _) {
          final jsBuffer = getRequest.result as JSUint8Array;
          getCompleter.complete(jsBuffer.toDart);
        }.toJS;
        getRequest.onerror = (web.Event _) {
          getCompleter.completeError(Exception('Failed to get value for $key'));
        }.toJS;
        result[key] = await getCompleter.future;
      }

      return result;
    } finally {
      db.close();
    }
  }

  Future<void> _clearStore(web.IDBDatabase db) async {
    final txn = db.transaction(_storeName.toJS, 'readwrite');
    final store = txn.objectStore(_storeName);
    store.clear();

    final completer = Completer<void>();
    txn.oncomplete = (web.Event _) {
      completer.complete();
    }.toJS;
    txn.onerror = (web.Event _) {
      completer.completeError(
        Exception('Failed to clear store: ${txn.error?.message}'),
      );
    }.toJS;
    await completer.future;
  }

  @override
  Future<void> clearCsvs() async {
    final db = await _openDb();
    try {
      await _clearStore(db);
    } finally {
      db.close();
    }
  }
}
