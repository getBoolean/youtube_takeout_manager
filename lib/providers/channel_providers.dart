import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/channel.dart';
import '../services/channel_cache_service.dart';
import '../services/google_auth_service.dart';
import '../services/youtube_channel_service.dart';
import 'auth_providers.dart';
import 'comment_providers.dart';
import 'live_chat_providers.dart';
import 'takeout_providers.dart';
import 'video_providers.dart';

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
    final title = c.channelTitle?.toLowerCase() ?? '';
    final id = c.channelId.toLowerCase();
    return title.contains(query) || id.contains(query);
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
  final _cacheService = ChannelCacheService();
  final _pendingIds = <String>{};
  bool _fetchInProgress = false;

  @override
  Map<String, String> build() => {};

  /// Loads cached channel thumbnails from local storage.
  Future<void> loadCache() async {
    final cached = await _cacheService.loadCachedThumbnails();
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

    final client = GoogleAuthService.instance
        .getAuthenticatedClient(authState.accessToken);
    final service = YoutubeChannelService();
    try {
      while (_pendingIds.isNotEmpty) {
        final batch = _pendingIds.take(10).toSet();
        _pendingIds.removeAll(batch);
        final fetched = await service.fetchChannelThumbnails(client, batch);
        state = {...state, ...fetched};
      }
      await _cacheService.saveThumbnails(state);
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

    final client = GoogleAuthService.instance
        .getAuthenticatedClient(authState.accessToken);
    final service = YoutubeChannelService();

    try {
      final fetched =
          await service.fetchChannelThumbnails(client, uncachedIds);
      state = {...state, ...fetched};
      await _cacheService.saveThumbnails(state);
    } finally {
      client.close();
    }
  }
}

@riverpod
List<Channel> channels(Ref ref) {
  final takeout = ref.watch(takeoutProvider);
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
