import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import '../data/channel_cache_repository.dart';
import '../data/youtube_channel_repository.dart';
import 'channel_providers.dart';

part 'channel_thumbnail_fetcher.g.dart';

/// How many channels without a picture the channel list gathers before it
/// fetches them.
const thumbnailBatchSize = 10;

/// How many channels one request asks for: the most one `channels.list`
/// call takes, for its 1 quota unit.
const _requestSize = 50;

/// Saved every so many requests, so a long run's pictures survive it being
/// cut short.
const _requestsBetweenSaves = 10;

/// Fetches channel pictures: for the channels the viewed channel
/// interacted with, once [thumbnailBatchSize] of them appear and the rest
/// once video titles are done; and whole lists at once, such as history's
/// channels, with [fetchNow]. Each request is counted against the quota;
/// channels YouTube has no picture for are remembered and not asked for
/// again. Signed out, nothing is fetched.
/// An effect: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class ChannelThumbnailFetcher extends _$ChannelThumbnailFetcher {
  final _pendingIds = <String>{};
  Future<void>? _running;

  @override
  void build() {
    ref.listen(channelsProvider, (_, channels) {
      queueChannelIds({for (final c in channels) c.channelId});
    });
    ref.listen(videoFetchProgressProvider, (previous, next) {
      if (previous != null && previous.isFetching && !next.isFetching) {
        flushQueue();
      }
    });
  }

  /// Queues [channelIds] without a picture yet, fetching once there's a
  /// batch of [thumbnailBatchSize].
  void queueChannelIds(Set<String> channelIds) {
    _queue(channelIds);
    if (_pendingIds.length >= thumbnailBatchSize) unawaited(_fetchPending());
  }

  /// Fetches whatever is still queued, and waits for it.
  Future<void> flushQueue() =>
      _pendingIds.isNotEmpty ? _fetchPending() : (_running ?? Future.value());

  /// Fetches pictures for [channelIds] without a picture yet, in the order
  /// given, without waiting for a batch.
  Future<void> fetchNow(Iterable<String> channelIds) {
    _queue(channelIds);
    return flushQueue();
  }

  void _queue(Iterable<String> channelIds) {
    final known = ref.read(channelThumbnailsProvider).value ?? const {};
    for (final id in channelIds) {
      if (id != unknownChannelId && !known.containsKey(id)) _pendingIds.add(id);
    }
  }

  /// Fetches everything queued, including what's queued meanwhile; while
  /// it runs, calls get the same run.
  Future<void> _fetchPending() => _running ??= _fetchAll().whenComplete(
    () => _running = null,
  );

  Future<void> _fetchAll() async {
    final sessionChannelId = ref.read(readSessionChannelIdProvider);
    if (sessionChannelId == null) return;

    final cache = ref.read(channelCacheRepositoryProvider);
    final notFound = await cache.loadNotFoundIds();
    final thumbnails = ref.read(channelThumbnailsProvider.notifier);
    final quota = ref.read(quotaProvider.notifier);
    final channels = ref.read(youtubeChannelRepositoryProvider);
    final client = ref
        .read(googleAuthRepositoryProvider)
        .getAuthenticatedClient(sessionChannelId);
    var requests = 0;
    var foundMissing = false;
    try {
      while (_pendingIds.isNotEmpty) {
        final batch = _pendingIds.take(_requestSize).toSet();
        _pendingIds.removeAll(batch);
        batch.removeAll(notFound);
        if (batch.isEmpty) continue;

        final Map<String, String> fetched;
        try {
          fetched = await channels.fetchChannelThumbnails(client, batch);
        } on Exception catch (e) {
          if (isSignInFailure(e)) rethrow;
          // Offline or refused: asked for again next time, not taken to be
          // gone.
          _pendingIds.addAll(batch);
          break;
        }
        await quota.recordUsage(QuotaOperation.channelsList);
        await thumbnails.add(fetched);
        final missing = batch.difference(fetched.keys.toSet());
        if (missing.isNotEmpty) {
          notFound.addAll(missing);
          foundMissing = true;
        }
        if (++requests % _requestsBetweenSaves == 0) {
          await thumbnails.persist();
        }
      }
    } catch (e) {
      if (!isSignInFailure(e)) rethrow;
      await ref
          .read(signInServiceProvider.notifier)
          .signInFailed(sessionChannelId);
    } finally {
      client.close();
      await thumbnails.persist();
      if (foundMissing) await cache.saveNotFoundIds(notFound);
    }
  }
}
