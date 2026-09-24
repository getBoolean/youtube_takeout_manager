import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/service/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/comments/service/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/service/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/quota/model/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/service/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/service/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/service/video_providers.dart';
import '../data/channel_cache_repository.dart';
import '../data/youtube_channel_repository.dart';
import '../model/channel.dart';

part 'channel_providers.g.dart';

@riverpod
class ChannelSearchQuery extends _$ChannelSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}

@riverpod
List<Channel> filteredChannels(Ref ref) {
  final channels = ref.watch(channelsProvider);
  final query = ref.watch(channelSearchQueryProvider).toLowerCase();
  if (query.isEmpty) return channels;
  return channels.where((c) {
    final title = c.channelTitle?.toLowerCase();
    if (title != null) return title.contains(query);
    return c.channelId.toLowerCase().contains(query);
  }).toList();
}

@riverpod
Map<String, String> channelTitlesFromVideos(Ref ref) {
  final videoMetadata = ref.watch(videoMetadataProvider).value ?? {};
  final titles = <String, String>{};
  for (final video in videoMetadata.values) {
    if (video.channelTitle != null && !titles.containsKey(video.channelId)) {
      titles[video.channelId] = video.channelTitle!;
    }
  }
  return titles;
}

@Riverpod(keepAlive: true)
class ChannelThumbnails extends _$ChannelThumbnails {
  ChannelCacheRepository get _cacheRepository =>
      ref.read(channelCacheRepositoryProvider);
  YoutubeChannelRepository get _channelRepository =>
      ref.read(youtubeChannelRepositoryProvider);

  final _pendingIds = <String>{};
  bool _fetchInProgress = false;

  @override
  Map<String, String> build() {
    ref.watch(channelCacheRepositoryProvider);
    loadCache();
    return {};
  }

  /// Loads cached channel thumbnails from local storage.
  Future<void> loadCache() async {
    final cached = await _cacheRepository.loadCachedThumbnails();
    if (cached.isNotEmpty) {
      state = {...state, ...cached};
    }
  }

  /// Queue channel IDs for thumbnail fetching.
  /// Buffers them and fetches in batches of 10.
  void queueChannelIds(Set<String> channelIds) {
    final uncached = channelIds.difference(state.keys.toSet());
    if (uncached.isEmpty) return;
    _pendingIds.addAll(uncached);
    if (_pendingIds.length >= 10 && !_fetchInProgress) {
      _fetchPending();
    }
  }

  /// Flush any remaining queued IDs (called when video stream completes).
  Future<void> flushQueue() async {
    if (_pendingIds.isNotEmpty && !_fetchInProgress) {
      await _fetchPending();
    }
  }

  Future<void> _fetchPending() async {
    if (_fetchInProgress || _pendingIds.isEmpty) return;
    _fetchInProgress = true;

    final authState = ref.read(authProvider);
    if (authState == null) {
      _fetchInProgress = false;
      return;
    }

    final client = ref
        .read(googleAuthRepositoryProvider)
        .getAuthenticatedClient(authState.accessToken);
    try {
      while (_pendingIds.isNotEmpty) {
        final batch = _pendingIds.take(10).toSet();
        _pendingIds.removeAll(batch);
        final fetched = await _channelRepository.fetchChannelThumbnails(
          client,
          batch,
        );
        await ref
            .read(quotaProvider.notifier)
            .recordUsage(QuotaOperation.channelsList);
        state = {...state, ...fetched};
      }
      await _cacheRepository.saveThumbnails(state);
    } finally {
      client.close();
      _fetchInProgress = false;
    }
  }

  /// Fetches thumbnails for channels not already cached (manual refresh).
  Future<void> fetchThumbnails(Set<String> channelIds) async {
    final authState = ref.read(authProvider);
    if (authState == null) return;

    final uncachedIds = channelIds.difference(state.keys.toSet());
    if (uncachedIds.isEmpty) return;

    final client = ref
        .read(googleAuthRepositoryProvider)
        .getAuthenticatedClient(authState.accessToken);
    try {
      final fetched = await _channelRepository.fetchChannelThumbnails(
        client,
        uncachedIds,
      );
      final batchCount = (uncachedIds.length + 49) ~/ 50;
      if (batchCount > 0) {
        await ref
            .read(quotaProvider.notifier)
            .recordUsage(QuotaOperation.channelsList, count: batchCount);
      }
      state = {...state, ...fetched};
      await _cacheRepository.saveThumbnails(state);
    } finally {
      client.close();
    }
  }
}

@riverpod
List<Channel> channels(Ref ref) {
  final takeout = ref.watch(takeoutProvider).value;
  if (takeout == null) return [];

  final commentsByChannel = ref.watch(commentsByChannelProvider);
  final liveChatsByChannel = ref.watch(liveChatsByChannelProvider);
  final subscriptions = takeout.subscriptionsByChannelId;

  // Collect all unique channel IDs from both comments and live chats
  final channelIds = <String>{
    ...commentsByChannel.keys,
    ...liveChatsByChannel.keys,
  };

  final channelTitlesFromVideos = ref.watch(channelTitlesFromVideosProvider);
  final thumbnails = ref.watch(channelThumbnailsProvider);

  final channels = channelIds.map((id) {
    final sub = subscriptions[id];
    final channelTitle = sub?.channelTitle ?? channelTitlesFromVideos[id];
    return Channel(
      channelId: id,
      channelTitle: channelTitle,
      channelUrl: sub?.channelUrl ?? 'https://www.youtube.com/channel/$id',
      thumbnailUrl: thumbnails[id],
      commentCount: commentsByChannel[id]?.length ?? 0,
      liveChatCount: liveChatsByChannel[id]?.length ?? 0,
    );
  }).toList();

  // Sort by total interactions descending
  channels.sort((a, b) => b.totalInteractions.compareTo(a.totalInteractions));
  return channels;
}

@riverpod
Channel? channelById(Ref ref, String channelId) {
  final takeout = ref.watch(takeoutProvider).value;
  if (takeout == null) return null;

  final commentsByChannel = ref.watch(commentsByChannelProvider);
  final liveChatsByChannel = ref.watch(liveChatsByChannelProvider);
  if (!commentsByChannel.containsKey(channelId) &&
      !liveChatsByChannel.containsKey(channelId)) {
    return null;
  }

  final sub = takeout.subscriptionsByChannelId[channelId];
  final titleFromVideos = ref.watch(channelTitlesFromVideosProvider)[channelId];
  final thumbnail = ref.watch(channelThumbnailsProvider)[channelId];
  return Channel(
    channelId: channelId,
    channelTitle: sub?.channelTitle ?? titleFromVideos,
    channelUrl: sub?.channelUrl ?? 'https://www.youtube.com/channel/$channelId',
    thumbnailUrl: thumbnail,
    commentCount: commentsByChannel[channelId]?.length ?? 0,
    liveChatCount: liveChatsByChannel[channelId]?.length ?? 0,
  );
}
