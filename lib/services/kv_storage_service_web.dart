import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'kv_storage_service.dart';

/// Web implementation: persists key-value data in IndexedDB.
///
/// On first use, migrates any existing SharedPreferences data from
/// localStorage (where `shared_preferences_web` stores it with a
/// `flutter.` key prefix).
class KvStorageServiceImpl implements KvStorageService {
  static const _dbName = 'app_kv_store';
  static const _storeName = 'entries';
  static const _version = 1;
  static const _migratedKey = '__migrated_v2__';
  static const _migratedV1Key = '__migrated__';

  static bool _migrationDone = false;

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

  Future<void> _migrateFromLocalStorage(web.IDBDatabase db) async {
    if (_migrationDone) return;
    _migrationDone = true;

    final sentinel = await _getRaw(db, _migratedKey);
    if (sentinel != null) return;

    // Keys whose values are JSON strings (maps).
    const stringKeys = [
      'deletion_queue',
      'quota_state',
      'cached_channel_thumbnails',
      'cached_video_metadata',
    ];

    // Keys whose values are JSON arrays (string lists).
    const listKeys = [
      'deleted_comment_ids',
      'deleted_live_chat_ids',
      'video_not_found_ids',
    ];

    const allKeys = [...stringKeys, ...listKeys];

    // Check if v1 migration ran (had a double-encoding bug for string values).
    final v1Sentinel = await _getRaw(db, _migratedV1Key);

    // Collect all values to write BEFORE opening the write transaction.
    // IndexedDB auto-commits transactions when you yield to the event loop,
    // so all async reads must finish before we start writing.
    final writes = <String, String>{};

    if (v1Sentinel != null) {
      // Repair v1: string values are still wrapped in an extra JSON encoding
      // layer. Read each, unwrap, and queue the corrected value for writing.
      for (final key in stringKeys) {
        final raw = await _getRaw(db, key);
        if (raw == null) continue;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is String) {
            writes[key] = decoded;
          }
        } on FormatException catch (_) {
          // Not valid JSON — leave as-is.
        }
      }
    } else {
      // Fresh migration from localStorage. shared_preferences_web stores
      // every value as json.encode(value), so we decode to get the original.
      final storage = web.window.localStorage;

      for (final key in allKeys) {
        final raw = storage.getItem('flutter.$key');
        if (raw == null) continue;
        final decoded = jsonDecode(raw);
        writes[key] =
            decoded is List ? jsonEncode(decoded) : decoded as String;
      }

      for (final key in allKeys) {
        storage.removeItem('flutter.$key');
      }
    }

    // Single synchronous write transaction — no awaits between put() calls.
    final txn = db.transaction(_storeName.toJS, 'readwrite');
    final store = txn.objectStore(_storeName);

    for (final entry in writes.entries) {
      store.put(entry.value.toJS, entry.key.toJS);
    }
    store.put('1'.toJS, _migratedKey.toJS);

    final completer = Completer<void>();
    txn.oncomplete = (web.Event _) {
      completer.complete();
    }.toJS;
    txn.onerror = (web.Event _) {
      completer.completeError(
        Exception('Migration failed: ${txn.error?.message}'),
      );
    }.toJS;
    await completer.future;
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
      await _migrateFromLocalStorage(db);
      return await _getRaw(db, key);
    } finally {
      db.close();
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    final db = await _openDb();
    try {
      await _migrateFromLocalStorage(db);
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
      await _migrateFromLocalStorage(db);
      await _removeRaw(db, key);
    } finally {
      db.close();
    }
  }
}
