import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import '../domain/video.dart';

part 'video_cache_repository.g.dart';

@Riverpod(keepAlive: true)
VideoCacheRepository videoCacheRepository(Ref ref) =>
    VideoCacheRepository(ref.watch(entryStoreProvider));

/// Persists video metadata and not-found IDs to local storage
/// so they survive app restarts and avoid redundant API calls.
class VideoCacheRepository {
  final EntryBox<Video> _videos;
  final EntrySet _notFound;

  VideoCacheRepository(EntryStore store)
    : _videos = EntryBox(
        store,
        EntryBoxes.videos,
        encode: (video) => video.toMap(),
        decode: (json) =>
            _upgraded(VideoMapper.fromMap(json! as Map<String, dynamic>)),
      ),
      _notFound = EntrySet(store, EntryBoxes.videosNotFound);

  Future<Map<String, Video>> loadCachedVideos() => _videos.load();

  /// Videos cached before `medium` thumbnails were fetched have the 120x90
  /// `default` one. YouTube serves `medium` next to it as `mqdefault`, the
  /// URL the API now returns.
  static final _smallThumbnail = RegExp(r'/default(_live)?\.jpg$');

  static Video _upgraded(Video video) {
    final thumbnail = video.thumbnailUrl;
    final upgraded = thumbnail?.replaceFirstMapped(
      _smallThumbnail,
      (match) => '/mqdefault${match[1] ?? ''}.jpg',
    );
    return upgraded == thumbnail
        ? video
        : video.copyWith(thumbnailUrl: upgraded);
  }

  Future<void> saveVideos(Map<String, Video> videos) => _videos.save(videos);

  Future<Set<String>> loadNotFoundIds() => _notFound.load();

  Future<void> saveNotFoundIds(Set<String> ids) => _notFound.save(ids);

  /// Notes [ids] as gone from YouTube, keeping the ones noted already.
  Future<void> addNotFoundIds(Set<String> ids) => _notFound.addAll(ids);

  Future<void> clearCache() async {
    await _videos.clear();
    await _notFound.clear();
  }
}
