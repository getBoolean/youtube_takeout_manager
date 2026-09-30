import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/video_format_cache_repository.dart';
import '../domain/video_format.dart';

part 'video_format_providers.g.dart';

/// The watched videos' lengths and shapes known on this device, by video
/// ID. Fetching more is `watchedVideoFormatFetcher`'s.
@Riverpod(keepAlive: true)
class VideoFormats extends _$VideoFormats {
  VideoFormatCacheRepository get _cache =>
      ref.read(videoFormatCacheRepositoryProvider);

  @override
  Future<Map<String, VideoFormat>> build() =>
      ref.watch(videoFormatCacheRepositoryProvider).loadFormats();

  /// Adds fetched formats.
  void addAll(Map<String, VideoFormat> formats) {
    if (formats.isEmpty) return;
    state = AsyncData(Map.unmodifiable({...?state.value, ...formats}));
  }

  /// Keeps the formats on this device.
  Future<void> persist() => _cache.saveFormats(state.value ?? const {});
}

/// How far along fetching the watched videos' formats is.
@Riverpod(keepAlive: true)
class VideoFormatProgress extends _$VideoFormatProgress {
  @override
  ({bool running, int done, int total}) build() =>
      (running: false, done: 0, total: 0);

  void start(int total) => state = (running: true, done: 0, total: total);

  void update(int done) =>
      state = (running: true, done: done, total: state.total);

  void complete() =>
      state = (running: false, done: state.total, total: state.total);
}
