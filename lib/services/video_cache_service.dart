import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/video.dart';

const _cachedVideosKey = 'cached_video_metadata';
const _notFoundIdsKey = 'video_not_found_ids';

/// Persists video metadata and not-found IDs to local storage
/// so they survive app restarts and avoid redundant API calls.
class VideoCacheService {
  Future<Map<String, Video>> loadCachedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cachedVideosKey);
    if (jsonStr == null) return {};

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return map.map(
      (key, value) =>
          MapEntry(key, VideoMapper.fromMap(value as Map<String, dynamic>)),
    );
  }

  Future<void> saveVideos(Map<String, Video> videos) async {
    final prefs = await SharedPreferences.getInstance();
    final map = videos.map((key, value) => MapEntry(key, value.toMap()));
    await prefs.setString(_cachedVideosKey, jsonEncode(map));
  }

  Future<Set<String>> loadNotFoundIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_notFoundIdsKey) ?? []).toSet();
  }

  Future<void> saveNotFoundIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_notFoundIdsKey, ids.toList());
  }
}
