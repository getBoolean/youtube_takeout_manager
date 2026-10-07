import 'dart:isolate';

/// Calls [died] once [thread], an isolate, exits.
void onThreadDeath(Object thread, void Function() died) {
  if (thread is! Isolate) return;
  final exited = RawReceivePort();
  exited.handler = (_) {
    exited.close();
    died();
  };
  thread.addOnExitListener(exited.sendPort);
}
