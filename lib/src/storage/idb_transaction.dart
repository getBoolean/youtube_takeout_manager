import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Opens the IndexedDB database [name], creating its one object store
/// [storeName] the first time.
Future<web.IDBDatabase> openIdbDatabase(
  String name,
  String storeName, {
  int version = 1,
}) {
  final completer = Completer<web.IDBDatabase>();
  final request = web.window.self.indexedDB.open(name, version);

  request.onupgradeneeded = (web.IDBVersionChangeEvent event) {
    final db = (event.target as web.IDBOpenDBRequest).result as web.IDBDatabase;
    if (!db.objectStoreNames.contains(storeName)) {
      db.createObjectStore(storeName);
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

/// Completes when [txn] commits, and fails if it errors or aborts. [action]
/// names what it was doing, for the error.
Future<void> transactionDone(web.IDBTransaction txn, String action) {
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
