import 'dart:convert';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

const _cachedThumbnailsKey = 'cached_channel_thumbnails';

/// Persists channel thumbnail URLs to local storage
/// so they survive app restarts and avoid redundant API calls.
class ChannelCacheService {
  final _kv = KvStorageService();

  Future<Map<String, String>> loadCachedThumbnails() async {
    final jsonStr = await _kv.getString(_cachedThumbnailsKey);
    if (jsonStr == null) return {};

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> saveThumbnails(Map<String, String> thumbnails) async {
    await _kv.setString(_cachedThumbnailsKey, jsonEncode(thumbnails));
  }

  Future<void> clearThumbnails() async {
    await _kv.remove(_cachedThumbnailsKey);
  }
}
