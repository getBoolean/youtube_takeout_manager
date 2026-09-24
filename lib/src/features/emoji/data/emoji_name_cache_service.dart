import 'dart:convert';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import 'youtube_emoji_name_service.dart';

const _cachedEmojiNamesKey = 'cached_emoji_names';
const _emojiResolveAttemptsKey = 'emoji_resolve_attempts';
const _emojiLookupPausedUntilKey = 'emoji_lookup_paused_until';

/// Persists custom emoji names resolved from YouTube, keyed by `emojiKey`,
/// plus when each video was last scanned so failures aren't retried on every
/// launch. Corrupt entries are dropped instead of failing the load.
class EmojiNameCacheService {
  final _kv = KvStorageService();

  Future<Map<String, ResolvedEmoji>> loadNames() async {
    final map = await _loadMap(_cachedEmojiNamesKey);
    return {
      for (final MapEntry(:key, :value) in map.entries)
        key: ?ResolvedEmoji.tryFromJson(value),
    };
  }

  Future<void> saveNames(Map<String, ResolvedEmoji> names) async {
    await _kv.setString(
      _cachedEmojiNamesKey,
      jsonEncode(names.map((key, value) => MapEntry(key, value.toJson()))),
    );
  }

  Future<Map<String, DateTime>> loadAttempts() async {
    final map = await _loadMap(_emojiResolveAttemptsKey);
    return {
      for (final MapEntry(:key, :value) in map.entries)
        if (value is String) key: ?DateTime.tryParse(value),
    };
  }

  Future<void> saveAttempts(Map<String, DateTime> attempts) async {
    await _kv.setString(
      _emojiResolveAttemptsKey,
      jsonEncode(
        attempts.map((key, value) => MapEntry(key, value.toIso8601String())),
      ),
    );
  }

  /// Lookups are paused after YouTube responds in an unexpected format.
  Future<DateTime?> loadPausedUntil() async {
    final value = await _kv.getString(_emojiLookupPausedUntilKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> savePausedUntil(DateTime until) async {
    await _kv.setString(_emojiLookupPausedUntilKey, until.toIso8601String());
  }

  Future<Map<String, Object?>> _loadMap(String key) async {
    final jsonStr = await _kv.getString(key);
    if (jsonStr == null) return const {};
    try {
      final decoded = jsonDecode(jsonStr);
      return decoded is Map<String, Object?> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }
}
