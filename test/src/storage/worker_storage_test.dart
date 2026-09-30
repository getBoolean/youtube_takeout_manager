import 'package:flutter_test/flutter_test.dart';
import 'package:squadron/squadron.dart';

import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import 'package:youtube_takeout_manager/src/storage/storage_service.dart';

/// Storage whose first [failures] calls fail as a crashed worker's do.
final class _Flaky extends StorageService {
  int failures;

  _Flaky(this.failures);

  @override
  Future<Map<String, String>> loadAll(String box) async {
    if (failures-- > 0) throw WorkerException('crashed');
    return {'k': 'v'};
  }
}

void main() {
  test(
    'a worker that fails is replaced once, and the call goes through',
    () async {
      var started = 0;
      final storage = WorkerStorage(() async => _Flaky(started++ == 0 ? 1 : 0));

      expect(await storage.run((s) => s.loadAll('box')), {'k': 'v'});
      expect(started, 2);
    },
  );

  test('failing again is passed on, not retried forever', () async {
    var started = 0;
    final storage = WorkerStorage(() async {
      started++;
      return _Flaky(1);
    });

    await expectLater(
      storage.run((s) => s.loadAll('box')),
      throwsA(isA<WorkerException>()),
    );
    expect(started, 2);
  });

  test('the worker is started once, on first use', () async {
    var started = 0;
    final storage = WorkerStorage(() async {
      started++;
      return _Flaky(0);
    });
    expect(started, 0);

    await storage.run((s) => s.loadAll('a'));
    await storage.run((s) => s.loadAll('b'));

    expect(started, 1);
  });
}
