import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/video_cache_repository.dart';
import '../domain/video.dart';

part 'video_providers.g.dart';

@Riverpod(keepAlive: true)
class VideoFetchProgress extends _$VideoFetchProgress {
  @override
  ({bool isFetching, int fetched, int total}) build() =>
      (isFetching: false, fetched: 0, total: 0);

  void start(int total) => state = (isFetching: true, fetched: 0, total: total);

  void update(int fetched) =>
      state = (isFetching: true, fetched: fetched, total: state.total);

  void complete() =>
      state = (isFetching: false, fetched: state.total, total: state.total);
}

/// Videos to fetch details of besides the viewed takeout's, e.g. those of
/// new items in a takeout being reviewed. Fetching them is
/// `videoTitleFetcher`'s.
@Riverpod(keepAlive: true)
class ExtraVideoIds extends _$ExtraVideoIds {
  @override
  Set<String> build() => const {};

  void set(Set<String> ids) => state = ids;

  void clear() => state = const {};
}

/// Details of the videos commented or chatted on, by video ID, kept on this
/// device. Fetching more is `videoTitleFetcher`'s.
@Riverpod(keepAlive: true)
class VideoMetadata extends _$VideoMetadata {
  VideoCacheRepository get _cache => ref.read(videoCacheRepositoryProvider);

  @override
  Stream<Map<String, Video>> build() async* {
    yield await ref.watch(videoCacheRepositoryProvider).loadCachedVideos();
  }

  /// Adds a fetched video.
  void add(Video video) => state = AsyncData(
    Map.unmodifiable({...?state.value, video.videoId: video}),
  );

  /// Adds fetched videos, at once.
  void addAll(Iterable<Video> videos) {
    final added = {for (final video in videos) video.videoId: video};
    if (added.isEmpty) return;
    state = AsyncData(Map.unmodifiable({...?state.value, ...added}));
  }

  /// Keeps the videos on this device.
  Future<void> persist() => _cache.saveVideos(state.value ?? const {});
}
