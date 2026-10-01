import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/data/quota_errors.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import '../data/video_cache_repository.dart';
import '../data/youtube_video_repository.dart';
import '../domain/video.dart';
import 'video_providers.dart';

part 'video_details_fetcher.g.dart';

/// Fetches details, such as descriptions, of videos asked for by ID, like
/// the watched videos AI is told about: signed in, while the quota lasts,
/// and only for those neither kept on this device nor known to be gone.
/// Each request is counted against the quota. Signed out, nothing is
/// fetched; what's kept is all there is. Once [fetch]'s `stop` says so, it
/// asks for nothing more.
///
/// A service: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class VideoDetailsFetcher extends _$VideoDetailsFetcher {
  @override
  void build() {}

  Future<void> fetch(Iterable<String> videoIds, {bool Function()? stop}) async {
    bool stopped() => stop?.call() ?? false;
    final sessionChannelId = ref.read(readSessionChannelIdProvider);
    if (sessionChannelId == null || stopped()) return;
    final quota = ref.read(quotaProvider.notifier);
    if ((await ref.read(quotaProvider.future)).usedUp) return;

    final cache = ref.read(videoCacheRepositoryProvider);
    final videos = ref.read(videoMetadataProvider.notifier);
    final kept = await ref.read(videoMetadataProvider.future);
    final gone = await cache.loadNotFoundIds();
    final wanted = {
      for (final id in videoIds)
        if (!kept.containsKey(id) && !gone.contains(id)) id,
    };
    if (wanted.isEmpty || stopped()) return;

    final client = ref
        .read(googleAuthRepositoryProvider)
        .getAuthenticatedClient(sessionChannelId);
    final fetched = <String>{};
    var batch = <Video>[];
    var complete = false;
    try {
      await for (final video
          in ref
              .read(youtubeVideoRepositoryProvider)
              .fetchVideoMetadataStream(
                client,
                wanted,
                // Counted as each request is answered; what came with it is
                // added then, in one change.
                onResponse: () {
                  videos.addAll(batch);
                  batch = [];
                  unawaited(quota.recordUsage(QuotaOperation.videosList));
                },
              )) {
        batch.add(video);
        fetched.add(video.videoId);
        // Leaving the stream ends it before its next request.
        if (stopped()) break;
      }
      complete = !stopped();
    } catch (e) {
      if (isQuotaExceeded(e)) {
        // Keep what came; the rest isn't gone, just not asked for until
        // the quota is back.
        await quota.markUsedUp();
      } else if (isSignInFailure(e)) {
        await ref
            .read(signInServiceProvider.notifier)
            .signInFailed(sessionChannelId);
      } else {
        rethrow;
      }
    } finally {
      client.close();
      videos.addAll(batch);
      await videos.persist();
    }
    if (!complete) return;
    final missing = wanted.difference(fetched);
    if (missing.isNotEmpty) await cache.addNotFoundIds(missing);
  }
}
