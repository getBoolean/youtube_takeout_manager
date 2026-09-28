import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

part 'channel_cache_repository.g.dart';

@Riverpod(keepAlive: true)
ChannelCacheRepository channelCacheRepository(Ref ref) =>
    ChannelCacheRepository(ref.watch(kvStorageServiceProvider));

const _cachedThumbnailsKey = 'cached_channel_thumbnails';
const _notFoundKey = 'channel_thumbnails_not_found';

/// Persists channel thumbnail URLs to local storage
/// so they survive app restarts and avoid redundant API calls.
class ChannelCacheRepository {
  final KvStorageService _kv;

  ChannelCacheRepository(this._kv);

  Future<Map<String, String>> loadCachedThumbnails() async {
    final jsonStr = await _kv.getString(_cachedThumbnailsKey);
    if (jsonStr == null) return {};

    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> saveThumbnails(Map<String, String> thumbnails) async {
    await _kv.setString(_cachedThumbnailsKey, jsonEncode(thumbnails));
  }

  /// Channels YouTube had no picture for, e.g. since deleted, so they
  /// aren't asked for again.
  Future<Set<String>> loadNotFoundIds() async {
    final jsonStr = await _kv.getString(_notFoundKey);
    if (jsonStr == null) return {};
    return {...(jsonDecode(jsonStr) as List<dynamic>).cast<String>()};
  }

  Future<void> saveNotFoundIds(Set<String> ids) =>
      _kv.setString(_notFoundKey, jsonEncode(ids.toList()));

  /// Forgets the pictures and the channels that had none.
  Future<void> clearThumbnails() async {
    await _kv.remove(_cachedThumbnailsKey);
    await _kv.remove(_notFoundKey);
  }
}
