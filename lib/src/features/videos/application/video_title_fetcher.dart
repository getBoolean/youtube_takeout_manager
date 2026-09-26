import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../data/video_cache_repository.dart';
import '../data/youtube_video_repository.dart';
import 'video_providers.dart';

part 'video_title_fetcher.g.dart';

/// Fetches details, like titles, of the viewed channel's videos not kept on
/// this device yet, with whichever sign-in can read them. Starts over when
/// that sign-in or the viewed takeout changes, dropping the run under way.
///
/// An effect: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
Stream<void> videoTitleFetcher(Ref ref) async* {
  // Watched before anything is awaited, so a change always starts over.
  final sessionChannelId = ref.watch(readSessionChannelIdProvider);
  final takeout = ref.watch(viewedTakeoutProvider).value;
  if (sessionChannelId == null || takeout == null) return;

  final cache = ref.read(videoCacheRepositoryProvider);
  final videos = ref.read(videoMetadataProvider.notifier);
  final cached = await ref.read(videoMetadataProvider.future);

  final videoIds = <String>{
    for (final c in takeout.comments) ?c.videoId,
    for (final c in takeout.liveChats) ?c.videoId,
  };
  final notFoundIds = await cache.loadNotFoundIds();
  final uncachedIds = videoIds
      .difference(cached.keys.toSet())
      .difference(notFoundIds);
  if (uncachedIds.isEmpty) return;

  final progress = ref.read(videoFetchProgressProvider.notifier);
  progress.start(uncachedIds.length);

  final client = ref
      .read(googleAuthRepositoryProvider)
      .getAuthenticatedClient(sessionChannelId);
  final fetchedIds = <String>{};

  try {
    await for (final video
        in ref
            .read(youtubeVideoRepositoryProvider)
            .fetchVideoMetadataStream(client, uncachedIds)) {
      videos.add(video);
      fetchedIds.add(video.videoId);
      progress.update(fetchedIds.length);
      yield null;
    }
  } catch (e) {
    if (!isSignInFailure(e)) rethrow;
    // Keep what was fetched, but don't take the rest to be gone: the
    // sign-in failed, not the videos.
    await videos.persist();
    await ref
        .read(signInServiceProvider.notifier)
        .signInFailed(sessionChannelId);
    return;
  } finally {
    client.close();
    progress.complete();
  }

  // Record quota usage for videos.list API calls.
  final batchCount = (uncachedIds.length + 49) ~/ 50;
  if (batchCount > 0) {
    await ref
        .read(quotaProvider.notifier)
        .recordUsage(QuotaOperation.videosList, count: batchCount);
  }

  await videos.persist();

  final newNotFound = uncachedIds.difference(fetchedIds);
  if (newNotFound.isNotEmpty) {
    await cache.saveNotFoundIds(notFoundIds.union(newNotFound));
  }
}
