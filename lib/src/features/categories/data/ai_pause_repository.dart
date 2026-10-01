import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

part 'ai_pause_repository.g.dart';

@Riverpod(keepAlive: true)
AiPauseRepository aiPauseRepository(Ref ref) =>
    AiPauseRepository(ref.watch(kvStorageServiceProvider));

/// Keeps when each AI service said it can be asked again, so the wait
/// counts while the app is closed. Each pause is kept with when it began,
/// so a clock moved back never makes it longer than it was.
class AiPauseRepository {
  static const _key = 'ai_paused_until';

  final KvStorageService _kv;

  AiPauseRepository(this._kv);

  /// When each paused service resumes, as of [now]; services without a
  /// pause, or whose pause can't be read, are left out.
  Future<Map<AiService, DateTime>> load({required DateTime now}) async {
    final pauses = <AiService, DateTime>{};
    for (final MapEntry(:key, :value) in (await _stored()).entries) {
      final service = AiService.values.asNameMap()[key];
      if (service == null) continue;
      if (value case {
        'resumeAt': final String resumeAt,
        'since': final String since,
      }) {
        final (resumes, began) = (
          DateTime.tryParse(resumeAt),
          DateTime.tryParse(since),
        );
        if (resumes == null || began == null) continue;
        // A clock moved back to before the pause began waits it all from
        // now, never longer.
        pauses[service] = now.isBefore(began)
            ? now.add(resumes.difference(began))
            : resumes;
      }
    }
    return pauses;
  }

  /// Keeps [service] paused until [resumeAt], the pause beginning [since].
  Future<void> save(
    AiService service,
    DateTime resumeAt, {
    required DateTime since,
  }) async {
    final stored = await _stored();
    stored[service.name] = {
      'resumeAt': resumeAt.toUtc().toIso8601String(),
      'since': since.toUtc().toIso8601String(),
    };
    await _kv.setString(_key, jsonEncode(stored));
  }

  Future<void> clear(AiService service) async {
    final stored = await _stored();
    if (stored.remove(service.name) == null) return;
    await _kv.setString(_key, jsonEncode(stored));
  }

  Future<Map<String, Object?>> _stored() async {
    final raw = await _kv.getString(_key);
    if (raw == null) return {};
    try {
      return {...jsonDecode(raw) as Map<String, Object?>};
    } on Object {
      return {};
    }
  }
}
