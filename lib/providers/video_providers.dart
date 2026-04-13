import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/quota_operation.dart';
import '../models/video.dart';
import '../services/google_auth_service.dart';
import '../services/video_cache_service.dart';
import '../services/youtube_video_service.dart';
import 'auth_providers.dart';
import 'quota_provider.dart';
import 'takeout_providers.dart';

part 'video_providers.g.dart';

@Riverpod(keepAlive: true)
class VideoFetchProgress extends _$VideoFetchProgress {
  @override
  ({bool isFetching, int fetched, int total}) build() =>
      (isFetching: false, fetched: 0, total: 0);

  void start(int total) =>
      state = (isFetching: true, fetched: 0, total: total);

  void update(int fetched) =>
      state = (isFetching: true, fetched: fetched, total: state.total);

  void complete() =>
      state = (isFetching: false, fetched: state.total, total: state.total);
}

@Riverpod(keepAlive: true)
class VideoMetadata extends _$VideoMetadata {
  final _cacheService = VideoCacheService();

  @override
  Stream<Map<String, Video>> build() async* {
    // Load cache first, yield immediately
    final cached = await _cacheService.loadCachedVideos();
    yield cached;

    // Check prerequisites for API fetching
    final authState = ref.watch(authProvider);
    final takeout = ref.watch(takeoutProvider).value;
    if (authState == null || takeout == null) return;

    // Collect all unique videoIds from comments and live chats
    final videoIds = <String>{};
    for (final c in takeout.comments) {
      if (c.videoId != null) videoIds.add(c.videoId!);
    }
    for (final c in takeout.liveChats) {
      if (c.videoId != null) videoIds.add(c.videoId!);
    }

    // Subtract already-cached and not-found IDs
    final notFoundIds = await _cacheService.loadNotFoundIds();
    final uncachedIds =
        videoIds.difference(cached.keys.toSet()).difference(notFoundIds);
    if (uncachedIds.isEmpty) return;

    final progress = ref.read(videoFetchProgressProvider.notifier);
    progress.start(uncachedIds.length);

    final client = GoogleAuthService.instance
        .getAuthenticatedClient(authState.accessToken);
    final service = YoutubeVideoService();
    final accumulated = Map<String, Video>.from(cached);
    var count = 0;

    try {
      await for (final video
          in service.fetchVideoMetadataStream(client, uncachedIds)) {
        accumulated[video.videoId] = video;
        count++;
        progress.update(count);
        yield Map.unmodifiable(accumulated);
      }

      // Record quota usage for videos.list API calls.
      final batchCount = (uncachedIds.length + 49) ~/ 50;
      if (batchCount > 0) {
        await ref.read(quotaProvider.notifier).recordUsage(
              QuotaOperation.videosList,
              count: batchCount,
            );
      }

      // Persist cache once at the end
      await _cacheService.saveVideos(accumulated);

      // Persist IDs that were not found
      final newNotFound = uncachedIds.difference(accumulated.keys.toSet());
      if (newNotFound.isNotEmpty) {
        final allNotFound = notFoundIds.union(newNotFound);
        await _cacheService.saveNotFoundIds(allNotFound);
      }
    } finally {
      client.close();
      progress.complete();
    }
  }
}
