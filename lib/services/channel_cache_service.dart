import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _cachedThumbnailsKey = 'cached_channel_thumbnails';

/// Persists channel thumbnail URLs to local storage
/// so they survive app restarts and avoid redundant API calls.
class ChannelCacheService {
  Future<Map<String, String>> loadCachedThumbnails() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cachedThumbnailsKey);
    if (jsonStr == null) return {};

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> saveThumbnails(Map<String, String> thumbnails) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedThumbnailsKey, jsonEncode(thumbnails));
  }
}
