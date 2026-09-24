import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/service/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/model/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/service/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/service/takeout_notifier.dart';
import '../data/video_cache_repository.dart';
import '../data/youtube_video_repository.dart';
import '../model/video.dart';

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

@Riverpod(keepAlive: true)
class VideoMetadata extends _$VideoMetadata {
  @override
  Stream<Map<String, Video>> build() async* {
    final cacheRepository = ref.watch(videoCacheRepositoryProvider);
    final videoRepository = ref.watch(youtubeVideoRepositoryProvider);
    final authRepository = ref.watch(googleAuthRepositoryProvider);

    // Load cache first, yield immediately
    final cached = await cacheRepository.loadCachedVideos();
    yield cached;

    // Re-run when auth or takeout changes, but read current values.
    ref.listen(authProvider, (_, _) => ref.invalidateSelf());
    ref.listen(takeoutProvider, (_, _) => ref.invalidateSelf());

    final authState = ref.read(authProvider);
    final takeout = ref.read(takeoutProvider).value;
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
    final notFoundIds = await cacheRepository.loadNotFoundIds();
    final uncachedIds = videoIds
        .difference(cached.keys.toSet())
        .difference(notFoundIds);
    if (uncachedIds.isEmpty) return;

    final progress = ref.read(videoFetchProgressProvider.notifier);
    progress.start(uncachedIds.length);

    final client = authRepository.getAuthenticatedClient(authState.accessToken);
    final accumulated = Map<String, Video>.from(cached);
    var count = 0;

    try {
      await for (final video in videoRepository.fetchVideoMetadataStream(
        client,
        uncachedIds,
      )) {
        accumulated[video.videoId] = video;
        count++;
        progress.update(count);
        yield Map.unmodifiable(accumulated);
      }

      // Record quota usage for videos.list API calls.
      final batchCount = (uncachedIds.length + 49) ~/ 50;
      if (batchCount > 0) {
        await ref
            .read(quotaProvider.notifier)
            .recordUsage(QuotaOperation.videosList, count: batchCount);
      }

      // Persist cache once at the end
      await cacheRepository.saveVideos(accumulated);

      // Persist IDs that were not found
      final newNotFound = uncachedIds.difference(accumulated.keys.toSet());
      if (newNotFound.isNotEmpty) {
        final allNotFound = notFoundIds.union(newNotFound);
        await cacheRepository.saveNotFoundIds(allNotFound);
      }
    } finally {
      client.close();
      progress.complete();
    }
  }
}
