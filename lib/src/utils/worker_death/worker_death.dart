import 'package:squadron/squadron.dart';

import 'thread_death_stub.dart'
    if (dart.library.io) 'thread_death_native.dart'
    if (dart.library.js_interop) 'thread_death_web.dart';

/// [make]s a worker, handing it a thread hook, that's terminated as soon
/// as its thread dies of itself: the calls under way on it then fail, and
/// it says it's stopped, rather than leaving them waiting forever (which is
/// what squadron does). [threadHook] is given the thread too.
W terminatedWhenItDies<W extends Worker>(
  W Function(PlatformThreadHook threadHook) make, {
  PlatformThreadHook? threadHook,
}) {
  late final W worker;
  worker = make((thread) {
    onThreadDeath(thread, () => worker.terminate());
    return threadHook?.call(thread);
  });
  return worker;
}
