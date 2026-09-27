import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'idb_transaction.dart';
import 'kv_storage_service.dart';

/// Web implementation: persists key-value data in IndexedDB.
class KvStorageServiceImpl implements KvStorageService {
  static const _dbName = 'app_kv_store';
  static const _storeName = 'entries';

  Future<web.IDBDatabase> _openDb() => openIdbDatabase(_dbName, _storeName);

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
    txn.objectStore(_storeName).put(value.toJS, key.toJS);
    return transactionDone(txn, 'put key "$key"');
  }

  Future<void> _removeRaw(web.IDBDatabase db, String key) {
    final txn = db.transaction(_storeName.toJS, 'readwrite');
    txn.objectStore(_storeName).delete(key.toJS);
    return transactionDone(txn, 'remove key "$key"');
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
  Future<bool?> getBoolean(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    return raw == 'true';
  }

  @override
  Future<void> setBoolean(String key, bool value) async {
    await setString(key, value ? 'true' : 'false');
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
