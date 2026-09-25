import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'takeout_repository.dart';

/// Web implementation: persists CSV data in IndexedDB, keyed by
/// `<account ID>/<path>`.
class TakeoutRepositoryImpl implements TakeoutRepository {
  static const _dbName = 'takeouts';

  /// Where files were saved before they were kept per account, keyed by path.
  static const _legacyDbName = 'takeout_csvs';
  static const _storeName = 'files';
  static const _version = 1;

  Future<web.IDBDatabase> _openDb(String name) {
    final completer = Completer<web.IDBDatabase>();
    final request = web.window.self.indexedDB.open(name, _version);

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

  /// Keys from `<account ID>/` up to the last possible key with that prefix.
  web.IDBKeyRange _accountRange(String accountId) {
    checkAccountId(accountId);
    return web.IDBKeyRange.bound('$accountId/'.toJS, '$accountId/￿'.toJS);
  }

  @override
  Future<void> saveCsvs(
    String accountId,
    Map<String, Uint8List> csvFiles,
  ) async {
    final range = _accountRange(accountId);
    final db = await _openDb(_dbName);
    try {
      // Clear and write in one transaction, so a failed save keeps the
      // previous data.
      final txn = db.transaction(_storeName.toJS, 'readwrite');
      final store = txn.objectStore(_storeName);

      store.delete(range);
      for (final entry in csvFiles.entries) {
        store.put(entry.value.toJS, '$accountId/${entry.key}'.toJS);
      }
      await _complete(txn, 'save CSVs');
    } finally {
      db.close();
    }
  }

  @override
  Future<Map<String, Uint8List>?> loadCsvs(String accountId) async {
    final range = _accountRange(accountId);
    final files = await _load(_dbName, range);
    return files?.map(
      (key, bytes) => MapEntry(key.substring(accountId.length + 1), bytes),
    );
  }

  @override
  Future<void> clearCsvs(String accountId) async {
    final range = _accountRange(accountId);
    final db = await _openDb(_dbName);
    try {
      final txn = db.transaction(_storeName.toJS, 'readwrite');
      txn.objectStore(_storeName).delete(range);
      await _complete(txn, 'clear CSVs');
    } finally {
      db.close();
    }
  }

  @override
  Future<Map<String, Uint8List>?> loadLegacyCsvs() => _load(_legacyDbName);

  @override
  Future<void> clearLegacyCsvs() async {
    final db = await _openDb(_legacyDbName);
    try {
      final txn = db.transaction(_storeName.toJS, 'readwrite');
      txn.objectStore(_storeName).clear();
      await _complete(txn, 'clear legacy CSVs');
    } finally {
      db.close();
    }
  }

  /// Loads every file in [dbName] whose key is in [range], or all files if
  /// [range] is null. Returns null if there are none.
  Future<Map<String, Uint8List>?> _load(
    String dbName, [
    web.IDBKeyRange? range,
  ]) async {
    final db = await _openDb(dbName);
    try {
      final txn = db.transaction(_storeName.toJS, 'readonly');
      final store = txn.objectStore(_storeName);

      // Get all keys
      final keysCompleter = Completer<List<String>>();
      final keysRequest = store.getAllKeys(range);
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

  Future<void> _complete(web.IDBTransaction txn, String action) {
    final completer = Completer<void>();
    void fail(web.Event _) {
      if (completer.isCompleted) return;
      completer.completeError(
        Exception('Failed to $action: ${txn.error?.message ?? 'aborted'}'),
      );
    }

    txn.oncomplete = (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    txn.onerror = fail.toJS;
    // A commit that fails, e.g. over the storage quota, only aborts.
    txn.onabort = fail.toJS;
    return completer.future;
  }
}
