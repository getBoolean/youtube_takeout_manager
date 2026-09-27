@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'package:youtube_takeout_manager/src/storage/idb_transaction.dart';

Future<web.IDBDatabase> _openDb() {
  final completer = Completer<web.IDBDatabase>();
  final request = web.window.self.indexedDB.open('idb_transaction_test', 1);
  request.onupgradeneeded = (web.IDBVersionChangeEvent event) {
    ((event.target as web.IDBOpenDBRequest).result as web.IDBDatabase)
        .createObjectStore('s');
  }.toJS;
  request.onsuccess = (web.Event _) {
    completer.complete(request.result as web.IDBDatabase);
  }.toJS;
  return completer.future;
}

void main() {
  test('completes when the transaction commits', () async {
    final db = await _openDb();
    addTearDown(() => db.close());
    final txn = db.transaction('s'.toJS, 'readwrite');
    txn.objectStore('s').put('v'.toJS, 'k'.toJS);

    await expectLater(transactionDone(txn, 'save'), completes);
  });

  test('fails, not hangs, when the transaction only aborts', () async {
    final db = await _openDb();
    addTearDown(() => db.close());
    // With no request pending, aborting fires no error event, only abort:
    // like a commit that fails over the storage quota.
    final txn = db.transaction('s'.toJS, 'readwrite');
    final done = transactionDone(txn, 'save');
    txn.abort();

    await expectLater(
      done.timeout(const Duration(seconds: 5)),
      throwsA(
        isA<Exception>().having((e) => '$e', 'message', contains('save')),
      ),
    );
  });
}
