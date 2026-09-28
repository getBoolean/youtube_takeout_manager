import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/data/quota_errors.dart';
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
/// channels, with [fetchNow], the channels on screen first ([fetchFirst]).
/// Each request is counted against the quota; channels YouTube has no
/// picture for are remembered and not asked for again. Signed out, nothing
/// is fetched.
/// An effect: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class ChannelThumbnailFetcher extends _$ChannelThumbnailFetcher {
  final _pendingIds = <String>{};

  /// Queued channels to ask for before the rest, the latest shown first:
  /// never more than a request's worth.
  var _firstIds = <String>{};

  /// Channels a request is out for. The channels shown change as their
  /// pictures arrive, so without these they'd be queued again.
  final _askingIds = <String>{};

  /// Channels YouTube has no picture for, once loaded from the device.
  Set<String>? _notFoundIds;
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

  /// Forgets which channels YouTube had no picture for, once the device's
  /// pictures are cleared, so they're asked for again.
  void forgetMissing() => _notFoundIds = null;

  /// Fetches whatever is still queued, and waits for it.
  Future<void> flushQueue() =>
      _pendingIds.isNotEmpty ? _fetchPending() : (_running ?? Future.value());

  /// Fetches pictures for [channelIds] without a picture yet, in the order
  /// given, without waiting for a batch.
  Future<void> fetchNow(Iterable<String> channelIds) {
    _queue(channelIds);
    return flushQueue();
  }

  /// Asks for those of [channelIds] already queued before the rest, e.g.
  /// the channels on screen, called as often as every frame. Starts
  /// nothing: those with a picture, none to get, or already being asked
  /// for aren't queued.
  void fetchFirst(Iterable<String> channelIds) {
    final first = {
      for (final id in channelIds)
        if (_pendingIds.contains(id)) id,
    };
    if (first.isEmpty) return;
    _firstIds = {...first, ..._firstIds}.take(_requestSize).toSet();
  }

  void _queue(Iterable<String> channelIds) {
    final known = ref.read(channelThumbnailsProvider).value ?? const {};
    final notFound = _notFoundIds ?? const {};
    for (final id in channelIds) {
      if (id != unknownChannelId &&
          !known.containsKey(id) &&
          !notFound.contains(id) &&
          !_askingIds.contains(id)) {
        _pendingIds.add(id);
      }
    }
  }

  /// Fetches everything queued, including what's queued meanwhile; while
  /// it runs, calls get the same run.
  Future<void> _fetchPending() =>
      _running ??= _fetchAll().whenComplete(() => _running = null);

  Future<void> _fetchAll() async {
    final sessionChannelId = ref.read(readSessionChannelIdProvider);
    if (sessionChannelId == null) return;
    final quota = ref.read(quotaProvider.notifier);
    // Nothing is asked for while YouTube says the quota is used up.
    if ((await ref.read(quotaProvider.future)).usedUp) return;

    final cache = ref.read(channelCacheRepositoryProvider);
    final notFound = _notFoundIds ??= await cache.loadNotFoundIds();
    // Queued before these were known to have none.
    _pendingIds.removeAll(notFound);
    _firstIds.removeAll(notFound);
    if (_pendingIds.isEmpty) return;
    final thumbnails = ref.read(channelThumbnailsProvider.notifier);
    final channels = ref.read(youtubeChannelRepositoryProvider);
    final client = ref
        .read(googleAuthRepositoryProvider)
        .getAuthenticatedClient(sessionChannelId);
    var requests = 0;
    var foundMissing = false;
    try {
      while (_pendingIds.isNotEmpty) {
        final batch = {
          ..._firstIds.where(_pendingIds.contains),
          ..._pendingIds.take(_requestSize),
        }.take(_requestSize).toSet();
        _pendingIds.removeAll(batch);
        _firstIds.removeAll(batch);
        batch.removeAll(notFound);
        if (batch.isEmpty) continue;

        _askingIds.addAll(batch);
        try {
          final Map<String, String> fetched;
          try {
            fetched = await channels.fetchChannelThumbnails(client, batch);
          } on Exception catch (e) {
            if (isSignInFailure(e)) rethrow;
            if (isQuotaExceeded(e)) await quota.markUsedUp();
            // Offline or refused: asked for again next time, first, not
            // taken to be gone.
            final rest = [..._pendingIds];
            _pendingIds
              ..clear()
              ..addAll(batch)
              ..addAll(rest);
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
        } finally {
          // Once they're pictured or known to have none.
          _askingIds.removeAll(batch);
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
      // Not when the device's pictures were cleared meanwhile.
      if (foundMissing && identical(notFound, _notFoundIds)) {
        await cache.saveNotFoundIds(notFound);
      }
    }
  }
}
