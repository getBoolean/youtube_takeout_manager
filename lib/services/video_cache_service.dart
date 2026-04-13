import 'dart:convert';

import '../models/video.dart';
import 'kv_storage_service.dart';

const _cachedVideosKey = 'cached_video_metadata';
const _notFoundIdsKey = 'video_not_found_ids';

/// Persists video metadata and not-found IDs to local storage
/// so they survive app restarts and avoid redundant API calls.
class VideoCacheService {
  final _kv = KvStorageService();

  Future<Map<String, Video>> loadCachedVideos() async {
    final jsonStr = await _kv.getString(_cachedVideosKey);
    if (jsonStr == null) return {};

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return map.map(
      (key, value) =>
          MapEntry(key, VideoMapper.fromMap(value as Map<String, dynamic>)),
    );
  }

  Future<void> saveVideos(Map<String, Video> videos) async {
    final map = videos.map((key, value) => MapEntry(key, value.toMap()));
    await _kv.setString(_cachedVideosKey, jsonEncode(map));
  }

  Future<Set<String>> loadNotFoundIds() async {
    return (await _kv.getStringList(_notFoundIdsKey) ?? []).toSet();
  }

  Future<void> saveNotFoundIds(Set<String> ids) async {
    await _kv.setStringList(_notFoundIdsKey, ids.toList());
  }

  Future<void> clearCache() async {
    await _kv.remove(_cachedVideosKey);
    await _kv.remove(_notFoundIdsKey);
  }
}
