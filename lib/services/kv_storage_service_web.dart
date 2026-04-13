import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'kv_storage_service.dart';

/// Web implementation: persists key-value data in IndexedDB.
class KvStorageServiceImpl implements KvStorageService {
  static const _dbName = 'app_kv_store';
  static const _storeName = 'entries';
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

  Future<String?> _getRaw(web.IDBDatabase db, String key) {
    final txn = db.transaction(_storeName.toJS, 'readonly');
    final store = txn.objectStore(_storeName);
    final request = store.get(key.toJS);

    final completer = Completer<String?>();
    request.onsuccess = (web.Event _) {
      final result = request.result;
      if (result == null || result.isUndefinedOrNull) {
        completer.complete(null);
      } else {
        completer.complete((result as JSString).toDart);
      }
    }.toJS;
    request.onerror = (web.Event _) {
      completer.completeError(
        Exception('Failed to get key "$key": ${request.error?.message}'),
      );
    }.toJS;

    return completer.future;
  }

  Future<void> _putRaw(web.IDBDatabase db, String key, String value) {
    final txn = db.transaction(_storeName.toJS, 'readwrite');
    final store = txn.objectStore(_storeName);
    store.put(value.toJS, key.toJS);

    final completer = Completer<void>();
    txn.oncomplete = (web.Event _) {
      completer.complete();
    }.toJS;
    txn.onerror = (web.Event _) {
      completer.completeError(
        Exception('Failed to put key "$key": ${txn.error?.message}'),
      );
    }.toJS;

    return completer.future;
  }

  Future<void> _removeRaw(web.IDBDatabase db, String key) {
    final txn = db.transaction(_storeName.toJS, 'readwrite');
    final store = txn.objectStore(_storeName);
    store.delete(key.toJS);

    final completer = Completer<void>();
    txn.oncomplete = (web.Event _) {
      completer.complete();
    }.toJS;
    txn.onerror = (web.Event _) {
      completer.completeError(
        Exception('Failed to remove key "$key": ${txn.error?.message}'),
      );
    }.toJS;

    return completer.future;
  }

  @override
  Future<String?> getString(String key) async {
    final db = await _openDb();
    try {
      return await _getRaw(db, key);
    } finally {
      db.close();
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    final db = await _openDb();
    try {
      await _putRaw(db, key, value);
    } finally {
      db.close();
    }
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<String>();
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await setString(key, jsonEncode(value));
  }

  @override
  Future<void> remove(String key) async {
    final db = await _openDb();
    try {
      await _removeRaw(db, key);
    } finally {
      db.close();
    }
  }
}
