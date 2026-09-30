import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/video_format.dart';

part 'video_format_cache_repository.g.dart';

@Riverpod(keepAlive: true)
VideoFormatCacheRepository videoFormatCacheRepository(Ref ref) =>
    VideoFormatCacheRepository(ref.watch(kvStorageServiceProvider));

const _formatsKey = 'video_formats';
const _notFoundIdsKey = 'video_formats_not_found';

/// Keeps the watched videos' lengths and shapes on this device, and the
/// videos YouTube no longer has, so neither is asked for again.
class VideoFormatCacheRepository {
  final KvStorageService _kv;

  VideoFormatCacheRepository(this._kv);

  /// Entries that can't be read are skipped, keeping the rest.
  Future<Map<String, VideoFormat>> loadFormats() async {
    final json = await _kv.getString(_formatsKey);
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return {
      for (final MapEntry(:key, :value) in map.entries) key: ?_read(value),
    };
  }

  static VideoFormat? _read(Object? value) {
    try {
      return VideoFormat.fromJson(value! as List<dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> saveFormats(Map<String, VideoFormat> formats) => _kv.setString(
    _formatsKey,
    jsonEncode({
      for (final MapEntry(:key, :value) in formats.entries) key: value.toJson(),
    }),
  );

  Future<Set<String>> loadNotFoundIds() async =>
      (await _kv.getStringList(_notFoundIdsKey) ?? const []).toSet();

  Future<void> saveNotFoundIds(Set<String> ids) =>
      _kv.setStringList(_notFoundIdsKey, ids.toList());

  Future<void> clear() async {
    await _kv.remove(_formatsKey);
    await _kv.remove(_notFoundIdsKey);
  }
}
