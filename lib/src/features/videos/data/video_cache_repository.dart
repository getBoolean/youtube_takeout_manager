import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../model/video.dart';

part 'video_cache_repository.g.dart';

@Riverpod(keepAlive: true)
VideoCacheRepository videoCacheRepository(Ref ref) =>
    VideoCacheRepository(ref.watch(kvStorageServiceProvider));

const _cachedVideosKey = 'cached_video_metadata';
const _notFoundIdsKey = 'video_not_found_ids';

/// Persists video metadata and not-found IDs to local storage
/// so they survive app restarts and avoid redundant API calls.
class VideoCacheRepository {
  final KvStorageService _kv;

  VideoCacheRepository(this._kv);

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
