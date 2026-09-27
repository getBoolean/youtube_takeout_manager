import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'package:youtube_takeout_manager/src/storage/idb_transaction.dart';
import '../domain/channel_id.dart';
import 'takeout_repository.dart';

/// Web implementation: persists CSV data in IndexedDB, keyed by
/// `<account ID>/<path>`.
class TakeoutRepositoryImpl implements TakeoutRepository {
  static const _dbName = 'takeouts';

  /// Where files were saved before they were kept per account, keyed by path.
  static const _legacyDbName = 'takeout_csvs';
  static const _storeName = 'files';

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
    // Clear and write in one transaction, so a failed save keeps the
    // previous data.
    await _withStore(_dbName, 'readwrite', 'save CSVs', (store) {
      store.delete(range);
      for (final entry in csvFiles.entries) {
        store.put(entry.value.toJS, '$accountId/${entry.key}'.toJS);
      }
    });
  }

  @override
  Future<Map<String, Uint8List>?> loadCsvs(
    String accountId, {
    bool Function(String path)? only,
  }) async {
    final prefix = accountId.length + 1;
    final files = await _load(
      _dbName,
      range: _accountRange(accountId),
      only: only == null ? null : (key) => only(key.substring(prefix)),
    );
    return files?.map((key, bytes) => MapEntry(key.substring(prefix), bytes));
  }

  @override
  Future<List<String>> listAccountIds() async {
    final keys = <String>[];
    await _withStore(_dbName, 'readonly', 'list takeouts', (store) {
      _getKeys(store, null, keys.addAll);
    });
    return {
      for (final key in keys)
        if (key.indexOf('/') case final slash when slash > 0)
          key.substring(0, slash),
    }.where(isChannelId).toList();
  }

  @override
  Future<void> clearCsvs(String accountId) async {
    final range = _accountRange(accountId);
    await _withStore(
      _dbName,
      'readwrite',
      'clear CSVs',
      (store) => store.delete(range),
    );
  }

  @override
  Future<Map<String, Uint8List>?> loadLegacyCsvs() => _load(_legacyDbName);

  @override
  Future<void> clearLegacyCsvs() => _withStore(
    _legacyDbName,
    'readwrite',
    'clear legacy CSVs',
    (store) => store.clear(),
  );

  /// Loads every file in [dbName] whose key is in [range] (or all files if
  /// it's null) and that [only] accepts, in one transaction. Returns null if
  /// there are none.
  Future<Map<String, Uint8List>?> _load(
    String dbName, {
    web.IDBKeyRange? range,
    bool Function(String key)? only,
  }) async {
    final files = <String, Uint8List>{};
    await _withStore(dbName, 'readonly', 'load CSVs', (store) {
      _getKeys(store, range, (keys) {
        for (final key in keys) {
          if (only != null && !only(key)) continue;
          final request = store.get(key.toJS);
          request.onsuccess = (web.Event _) {
            files[key] = (request.result as JSUint8Array).toDart;
          }.toJS;
        }
      });
    });
    return files.isEmpty ? null : files;
  }

  /// Opens [dbName], makes requests with [start] in one [mode] transaction on
  /// its store, and completes when that commits. Fails, saying it couldn't
  /// [action], if any request does.
  ///
  /// Requests must all be made in [start] or in their callbacks: a
  /// transaction commits once it has none left, so one made after an await
  /// would find it gone.
  Future<void> _withStore(
    String dbName,
    String mode,
    String action,
    void Function(web.IDBObjectStore store) start,
  ) async {
    final db = await openIdbDatabase(dbName, _storeName);
    try {
      final txn = db.transaction(_storeName.toJS, mode);
      start(txn.objectStore(_storeName));
      await transactionDone(txn, action);
    } finally {
      db.close();
    }
  }

  /// Asks [store] for its keys within [range], or all of them if it's null,
  /// and passes them to [onKeys].
  void _getKeys(
    web.IDBObjectStore store,
    web.IDBKeyRange? range,
    void Function(List<String> keys) onKeys,
  ) {
    final request = store.getAllKeys(range);
    request.onsuccess = (web.Event _) {
      final keys = request.result as JSArray<JSString>;
      onKeys([for (final key in keys.toDart) key.toDart]);
    }.toJS;
  }
}
