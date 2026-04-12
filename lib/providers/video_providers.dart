import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/video.dart';
import '../services/google_auth_service.dart';
import '../services/video_cache_service.dart';
import '../services/youtube_video_service.dart';
import 'auth_providers.dart';
import 'takeout_providers.dart';

part 'video_providers.g.dart';

@Riverpod(keepAlive: true)
class VideoMetadata extends _$VideoMetadata {
  final _cacheService = VideoCacheService();

  @override
  Map<String, Video> build() => {};

  /// Loads cached video metadata from local storage.
  Future<void> loadCache() async {
    final cached = await _cacheService.loadCachedVideos();
    if (cached.isNotEmpty) {
      state = {...state, ...cached};
    }
  }

  /// Fetches metadata for videos not already cached.
  /// Requires authentication.
  Future<void> fetchMetadata() async {
    final authState = ref.read(authProvider);
    if (authState == null) return;

    final takeout = ref.read(takeoutProvider);
    if (takeout == null) return;

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
    final uncachedIds = videoIds
        .difference(state.keys.toSet())
        .difference(notFoundIds);

    if (uncachedIds.isEmpty) return;

    final client =
        GoogleAuthService.instance.getAuthenticatedClient(authState.accessToken);
    final service = YoutubeVideoService();

    try {
      final fetched = await service.fetchVideoMetadata(client, uncachedIds);

      // Merge new results into state
      state = {...state, ...fetched};
      await _cacheService.saveVideos(state);

      // Persist IDs that were not found
      final newNotFound = uncachedIds.difference(fetched.keys.toSet());
      if (newNotFound.isNotEmpty) {
        final allNotFound = notFoundIds.union(newNotFound);
        await _cacheService.saveNotFoundIds(allNotFound);
      }
    } finally {
      client.close();
    }
  }
}
