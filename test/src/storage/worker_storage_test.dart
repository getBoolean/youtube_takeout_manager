import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squadron/squadron.dart';

import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import 'package:youtube_takeout_manager/src/storage/storage_service.dart';

/// Storage whose first [failures] calls fail, as a squadron worker passes
/// errors on; [dead] says whether the worker behind it died.
final class _Fake extends StorageService {
  int failures;
  bool dead;
  final Completer<void>? hold;

  _Fake({this.failures = 0, this.dead = false, this.hold});

  @override
  Future<Map<String, String>> loadAll(String box) async {
    await hold?.future;
    if (failures-- > 0) throw WorkerException('failed');
    return {'k': 'v'};
  }
}

void main() {
  bool died(StorageService service) => (service as _Fake).dead;

  test('an operation that fails is passed on, and the worker kept', () async {
    var started = 0;
    final storage = WorkerStorage(() async {
      started++;
      return _Fake(failures: 1);
    }, isDead: died);

    await expectLater(
      storage.run((s) => s.loadAll('box')),
      throwsA(isA<WorkerException>()),
    );
    expect(await storage.run((s) => s.loadAll('box')), {'k': 'v'});
    expect(started, 1);
  });

  test(
    'a worker that died is replaced once, and the call goes through',
    () async {
      var started = 0;
      final storage = WorkerStorage(() async {
        started++;
        return started == 1 ? _Fake(failures: 1, dead: true) : _Fake();
      }, isDead: died);

      expect(await storage.run((s) => s.loadAll('box')), {'k': 'v'});
      expect(started, 2);
    },
  );

  test('dying again is passed on, not retried forever', () async {
    var started = 0;
    final storage = WorkerStorage(() async {
      started++;
      return _Fake(failures: 1, dead: true);
    }, isDead: died);

    await expectLater(
      storage.run((s) => s.loadAll('box')),
      throwsA(isA<WorkerException>()),
    );
    expect(started, 2);
  });

  test('a start that fails is tried again on the next call', () async {
    var started = 0;
    final storage = WorkerStorage(() async {
      if (started++ == 0) throw StateError('no storage yet');
      return _Fake();
    }, isDead: died);

    await expectLater(storage.run((s) => s.loadAll('box')), throwsStateError);
    expect(await storage.run((s) => s.loadAll('box')), {'k': 'v'});
    expect(started, 2);
  });

  test(
    'calls under way when the worker dies all go on to its replacement',
    () async {
      final hold = Completer<void>();
      var started = 0;
      final storage = WorkerStorage(() async {
        started++;
        return started == 1
            ? _Fake(failures: 2, dead: true, hold: hold)
            : _Fake();
      }, isDead: died);

      final first = storage.run((s) => s.loadAll('a'));
      final second = storage.run((s) => s.loadAll('b'));
      await pumpEventQueue();
      hold.complete();

      expect(await Future.wait([first, second]), [
        {'k': 'v'},
        {'k': 'v'},
      ]);
      expect(started, 2);
    },
  );

  test('the worker is started once, on first use', () async {
    var started = 0;
    final storage = WorkerStorage(() async {
      started++;
      return _Fake();
    }, isDead: died);
    expect(started, 0);

    await storage.run((s) => s.loadAll('a'));
    await storage.run((s) => s.loadAll('b'));

    expect(started, 1);
  });

  test('a real worker keeps running after an operation fails', () async {
    final dir = await Directory.systemTemp.createTemp('worker_storage');
    var started = 0;
    // Not opened yet: its calls fail, as an operation's own error.
    final storage = WorkerStorage(() async {
      started++;
      return StorageServiceWorker();
    });
    addTearDown(() async {
      await storage.stop();
      await dir.delete(recursive: true);
    });

    await expectLater(
      storage.run((s) => s.loadAll(EntryBoxes.videos)),
      throwsA(isA<SquadronException>()),
    );
    await storage.run((s) => s.open(dir.path));
    await storage.run((s) => s.putAll(EntryBoxes.videos, {'v1': '1'}));

    expect(await storage.run((s) => s.loadAll(EntryBoxes.videos)), {'v1': '1'});
    expect(started, 1);
  });
}
