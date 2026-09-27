import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import '../data/youtube_channel_repository.dart';
import 'channel_providers.dart';

part 'channel_thumbnail_fetcher.g.dart';

/// Fetches pictures for the channels the viewed channel interacted with, in
/// batches of 10 as they appear, and the rest once video titles are done.
/// An effect: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class ChannelThumbnailFetcher extends _$ChannelThumbnailFetcher {
  final _pendingIds = <String>{};
  var _fetchInProgress = false;

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
  /// batch of 10.
  void queueChannelIds(Set<String> channelIds) {
    final known = {...?ref.read(channelThumbnailsProvider).value?.keys};
    final uncached = channelIds.difference(known).difference(const {
      unknownChannelId,
    });
    if (uncached.isEmpty) return;
    _pendingIds.addAll(uncached);
    if (_pendingIds.length >= 10 && !_fetchInProgress) {
      _fetchPending();
    }
  }

  /// Fetches whatever is still queued.
  Future<void> flushQueue() async {
    if (_pendingIds.isNotEmpty && !_fetchInProgress) {
      await _fetchPending();
    }
  }

  Future<void> _fetchPending() async {
    if (_fetchInProgress || _pendingIds.isEmpty) return;
    final sessionChannelId = ref.read(readSessionChannelIdProvider);
    if (sessionChannelId == null) return;
    _fetchInProgress = true;

    final thumbnails = ref.read(channelThumbnailsProvider.notifier);
    final client = ref
        .read(googleAuthRepositoryProvider)
        .getAuthenticatedClient(sessionChannelId);
    try {
      while (_pendingIds.isNotEmpty) {
        final batch = _pendingIds.take(10).toSet();
        _pendingIds.removeAll(batch);
        final fetched = await ref
            .read(youtubeChannelRepositoryProvider)
            .fetchChannelThumbnails(client, batch);
        await ref
            .read(quotaProvider.notifier)
            .recordUsage(QuotaOperation.channelsList);
        await thumbnails.add(fetched);
      }
      await thumbnails.persist();
    } catch (e) {
      if (!isSignInFailure(e)) rethrow;
      await ref
          .read(signInServiceProvider.notifier)
          .signInFailed(sessionChannelId);
    } finally {
      client.close();
      _fetchInProgress = false;
    }
  }
}
