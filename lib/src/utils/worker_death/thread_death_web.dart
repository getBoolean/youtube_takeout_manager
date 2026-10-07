import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Calls [died] once [thread], a Web Worker, fails of itself.
void onThreadDeath(Object thread, void Function() died) {
  // squadron's threads are Web Workers on the web.
  (thread as web.Worker).addEventListener(
    'error',
    ((web.Event _) => died()).toJS,
  );
}
