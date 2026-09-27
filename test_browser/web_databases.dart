import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Deletes the IndexedDB databases [names], so each test starts empty.
Future<void> deleteDatabases(List<String> names) async {
  for (final name in names) {
    final done = Completer<void>();
    final request = web.window.self.indexedDB.deleteDatabase(name);
    request.onsuccess = (web.Event _) {
      done.complete();
    }.toJS;
    request.onerror = (web.Event _) {
      done.completeError(StateError('Could not delete $name'));
    }.toJS;
    await done.future;
  }
}

/// Opens [name] directly, creating [storeName], as the app would.
Future<web.IDBDatabase> openRaw(String name, String storeName) {
  final done = Completer<web.IDBDatabase>();
  final request = web.window.self.indexedDB.open(name, 1);
  request.onupgradeneeded = (web.IDBVersionChangeEvent event) {
    final db = (event.target as web.IDBOpenDBRequest).result as web.IDBDatabase;
    if (!db.objectStoreNames.contains(storeName)) {
      db.createObjectStore(storeName);
    }
  }.toJS;
  request.onsuccess = (web.Event _) {
    done.complete(request.result as web.IDBDatabase);
  }.toJS;
  request.onerror = (web.Event _) {
    done.completeError(StateError('Could not open $name'));
  }.toJS;
  return done.future;
}

/// Writes [values] into [storeName] of [name] directly, like an older version
/// of the app did.
Future<void> writeRaw(
  String name,
  String storeName,
  Map<String, JSAny> values,
) async {
  final db = await openRaw(name, storeName);
  try {
    final done = Completer<void>();
    final txn = db.transaction(storeName.toJS, 'readwrite');
    final store = txn.objectStore(storeName);
    for (final MapEntry(:key, :value) in values.entries) {
      store.put(value, key.toJS);
    }
    txn.oncomplete = (web.Event _) {
      done.complete();
    }.toJS;
    txn.onerror = (web.Event _) {
      done.completeError(StateError('Could not write $name'));
    }.toJS;
    await done.future;
  } finally {
    db.close();
  }
}
