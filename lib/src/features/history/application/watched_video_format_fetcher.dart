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
import 'package:youtube_takeout_manager/src/features/videos/application/video_format_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_format_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/youtube_video_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video_format.dart';
import 'history_shown.dart';
import 'takeout_history_notifier.dart';

part 'watched_video_format_fetcher.g.dart';

/// How many batches are fetched between saves.
const _saveEvery = 10;

/// Fetches the length and shape of every watched video not known yet, the
/// newest first, to tell Shorts apart: YouTube has no field saying which is
/// which. Waits for the history screen to be opened, and needs a sign-in.
/// Starts over when the sign-in or the history changes, dropping the run
/// under way.
///
/// An effect: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
Stream<void> watchedVideoFormatFetcher(Ref ref) async* {
  // History is only loaded once its screen has been opened.
  if (!ref.watch(historyShownProvider)) return;
  final sessionChannelId = ref.watch(readSessionChannelIdProvider);
  // Nothing is asked for while YouTube says the quota is used up.
  final usedUp = ref.watch(
    quotaProvider.select((quota) => quota.value?.usedUp ?? false),
  );
  if (sessionChannelId == null || usedUp) return;
  final history = ref.watch(takeoutHistoryProvider).value;
  if (history == null) return;

  final cache = ref.read(videoFormatCacheRepositoryProvider);
  final formats = ref.read(videoFormatsProvider.notifier);
  final known = await ref.read(videoFormatsProvider.future);
  final notFound = await cache.loadNotFoundIds();
  // Still loading when first watched above.
  if ((await ref.read(quotaProvider.future)).usedUp) return;

  // Watched videos are newest first; ones watched through a Shorts link are
  // known to be Shorts already.
  final ids = <String>{
    for (final watch in history.history.watches)
      if (!watch.isShort)
        if (watch.videoId case final id?)
          if (!known.containsKey(id) && !notFound.contains(id)) id,
  }.toList();
  if (ids.isEmpty) return;

  final progress = ref.read(videoFormatProgressProvider.notifier);
  progress.start(ids.length);
  final client = ref
      .read(googleAuthRepositoryProvider)
      .getAuthenticatedClient(sessionChannelId);
  // Dropping this run stops its requests, which fail uncounted.
  ref.onDispose(client.close);
  // Read up front: a change drops this run, after which ref can't be used,
  // but what it did is still saved and counted.
  final quota = ref.read(quotaProvider.notifier);
  final signIns = ref.read(signInServiceProvider.notifier);
  final asked = <String>{};
  final fetched = <String, VideoFormat>{};
  var batch = <String, VideoFormat>{};
  var responses = 0;

  try {
    await for (final (id, format)
        in ref
            .read(youtubeVideoRepositoryProvider)
            .fetchVideoFormats(
              client,
              ids,
              onResponse: () {
                // Each answer covers the next batch of IDs asked for.
                asked.addAll(
                  ids
                      .skip(responses * YoutubeVideoRepository.batchSize)
                      .take(YoutubeVideoRepository.batchSize),
                );
                responses++;
                unawaited(quota.recordUsage(QuotaOperation.videosList));
                formats.addAll(batch);
                batch = {};
                progress.update(asked.length);
                if (responses % _saveEvery == 0) unawaited(formats.persist());
              },
            )) {
      fetched[id] = format;
      batch[id] = format;
      yield null;
    }
    formats.addAll(batch);
  } catch (e) {
    formats.addAll(batch);
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
    await formats.persist();
  }

  // Asked for and not answered: YouTube no longer has them.
  final gone = asked.difference(fetched.keys.toSet());
  if (gone.isNotEmpty) await cache.saveNotFoundIds(notFound.union(gone));
}
