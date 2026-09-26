import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

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
