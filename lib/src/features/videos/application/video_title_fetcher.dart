import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/data/quota_errors.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../data/video_cache_repository.dart';
import '../data/youtube_video_repository.dart';
import 'video_providers.dart';

part 'video_title_fetcher.g.dart';

/// Fetches details, like titles, of the viewed channel's videos and the
/// [ExtraVideoIds] not kept on this device yet, with whichever sign-in can
/// read them. Starts over when that sign-in, the viewed takeout or the extra
/// videos change, dropping the run under way.
///
/// An effect: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
Stream<void> videoTitleFetcher(Ref ref) async* {
  // Watched before anything is awaited, so a change always starts over.
  final sessionChannelId = ref.watch(readSessionChannelIdProvider);
  final takeout = ref.watch(viewedTakeoutProvider).value;
  final extraIds = ref.watch(extraVideoIdsProvider);
  // Nothing is asked for while YouTube says the quota is used up.
  final usedUp = ref.watch(
    quotaProvider.select((quota) => quota.value?.usedUp ?? false),
  );
  if (sessionChannelId == null || takeout == null || usedUp) return;

  final cache = ref.read(videoCacheRepositoryProvider);
  final videos = ref.read(videoMetadataProvider.notifier);
  final cached = await ref.read(videoMetadataProvider.future);

  final videoIds = <String>{
    for (final c in takeout.comments) ?c.videoId,
    for (final c in takeout.liveChats) ?c.videoId,
    ...extraIds,
  };
  final notFoundIds = await cache.loadNotFoundIds();
  // Still loading when first watched above.
  if ((await ref.read(quotaProvider.future)).usedUp) return;
  final uncachedIds = videoIds
      .difference(cached.keys.toSet())
      .difference(notFoundIds);
  if (uncachedIds.isEmpty) return;

  final progress = ref.read(videoFetchProgressProvider.notifier);
  progress.start(uncachedIds.length);

  final client = ref
      .read(googleAuthRepositoryProvider)
      .getAuthenticatedClient(sessionChannelId);
  // Dropping this run stops its requests, which fail uncounted.
  ref.onDispose(client.close);
  // Read up front: a change of sign-in or videos drops this run, after
  // which ref can't be used, but what it did is still saved and counted.
  final quota = ref.read(quotaProvider.notifier);
  final signIns = ref.read(signInServiceProvider.notifier);
  final fetchedIds = <String>{};

  try {
    await for (final video
        in ref
            .read(youtubeVideoRepositoryProvider)
            .fetchVideoMetadataStream(
              client,
              uncachedIds,
              // Counted as each request is answered, so usage shows as it
              // grows.
              onResponse: () =>
                  unawaited(quota.recordUsage(QuotaOperation.videosList)),
            )) {
      videos.add(video);
      fetchedIds.add(video.videoId);
      progress.update(fetchedIds.length);
      yield null;
    }
  } catch (e) {
    if (isQuotaExceeded(e)) {
      // Keep what was fetched; the rest isn't gone, just not asked for
      // until the quota is back.
      await quota.markUsedUp();
      return;
    }
    if (!isSignInFailure(e)) rethrow;
    // Keep what was fetched, but don't take the rest to be gone: the
    // sign-in failed, not the videos.
    await signIns.signInFailed(sessionChannelId);
    return;
  } finally {
    client.close();
    progress.complete();
    // Also when this run is dropped, so what it fetched isn't lost.
    await videos.persist();
  }

  final newNotFound = uncachedIds.difference(fetchedIds);
  if (newNotFound.isNotEmpty) {
    await cache.saveNotFoundIds(notFoundIds.union(newNotFound));
  }
}
