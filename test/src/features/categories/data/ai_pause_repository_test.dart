import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_pause_repository.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

final _now = DateTime.utc(2026, 10, 1, 12);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  AiPauseRepository repository() => AiPauseRepository(KvStorageService());

  test('pauses saved load again after a restart', () async {
    final jev = _now.add(const Duration(minutes: 5));
    final claude = _now.add(const Duration(minutes: 2));
    await repository().save(AiService.jev, jev, since: _now);
    await repository().save(AiService.claude, claude, since: _now);

    expect(await repository().load(now: _now), {
      AiService.jev: jev,
      AiService.claude: claude,
    });
  });

  test("clearing a service's pause keeps the other's", () async {
    final claude = _now.add(const Duration(minutes: 2));
    await repository().save(
      AiService.jev,
      _now.add(const Duration(minutes: 5)),
      since: _now,
    );
    await repository().save(AiService.claude, claude, since: _now);

    await repository().clear(AiService.jev);

    expect(await repository().load(now: _now), {AiService.claude: claude});
  });

  test('a clock moved back never makes the wait longer than it was', () async {
    await repository().save(
      AiService.jev,
      _now.add(const Duration(minutes: 5)),
      since: _now,
    );
    final earlier = _now.subtract(const Duration(hours: 1));

    expect(await repository().load(now: earlier), {
      AiService.jev: earlier.add(const Duration(minutes: 5)),
    });
  });

  test('nothing loads before anything is saved', () async {
    expect(await repository().load(now: _now), isEmpty);
  });

  test('pauses that cannot be read load as none', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.ai_paused_until': '{"jev": {"resumeAt": "soon"}, "x": 1}',
    });

    expect(await repository().load(now: _now), isEmpty);
  });
}
