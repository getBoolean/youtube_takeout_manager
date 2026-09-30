import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import '../domain/video_format.dart';

part 'video_format_cache_repository.g.dart';

@Riverpod(keepAlive: true)
VideoFormatCacheRepository videoFormatCacheRepository(Ref ref) =>
    VideoFormatCacheRepository(ref.watch(entryStoreProvider));

/// Keeps the watched videos' lengths and shapes on this device, and the
/// videos YouTube no longer has, so neither is asked for again.
class VideoFormatCacheRepository {
  final EntryBox<VideoFormat> _formats;
  final EntrySet _notFound;

  VideoFormatCacheRepository(EntryStore store)
    : _formats = EntryBox(
        store,
        EntryBoxes.videoFormats,
        encode: (format) => format.toJson(),
        decode: (json) => VideoFormat.fromJson(json! as List<dynamic>),
      ),
      _notFound = EntrySet(store, EntryBoxes.videoFormatsNotFound);

  /// Entries that can't be read are skipped, keeping the rest.
  Future<Map<String, VideoFormat>> loadFormats() => _formats.load();

  Future<void> saveFormats(Map<String, VideoFormat> formats) =>
      _formats.save(formats);

  Future<Set<String>> loadNotFoundIds() => _notFound.load();

  Future<void> saveNotFoundIds(Set<String> ids) => _notFound.save(ids);

  Future<void> clear() async {
    await _formats.clear();
    await _notFound.clear();
  }
}
