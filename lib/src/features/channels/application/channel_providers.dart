import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import '../data/channel_cache_repository.dart';
import '../domain/channel.dart';

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
  final query = foldForSearch(ref.watch(channelSearchQueryProvider));
  if (query.isEmpty) return channels;
  return channels.where((c) {
    final title = c.channelTitle;
    if (title != null) return foldForSearch(title).contains(query);
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

/// Channel pictures by channel ID, kept on this device. Fetching more is
/// `ChannelThumbnailFetcher`'s.
@Riverpod(keepAlive: true)
class ChannelThumbnails extends _$ChannelThumbnails {
  ChannelCacheRepository get _cacheRepository =>
      ref.read(channelCacheRepositoryProvider);

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

  /// Adds fetched pictures by channel ID.
  void add(Map<String, String> thumbnails) => state = {...state, ...thumbnails};

  /// Keeps the pictures on this device.
  Future<void> persist() => _cacheRepository.saveThumbnails(state);
}

@riverpod
List<Channel> channels(Ref ref) {
  final takeout = ref.watch(viewedTakeoutProvider).value;
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
    final commentCount = commentsByChannel[id]?.length ?? 0;
    final liveChatCount = liveChatsByChannel[id]?.length ?? 0;
    if (id == unknownChannelId) {
      return _unknownChannel(commentCount, liveChatCount);
    }
    final sub = subscriptions[id];
    final channelTitle = sub?.channelTitle ?? channelTitlesFromVideos[id];
    return Channel(
      channelId: id,
      channelTitle: channelTitle,
      channelUrl: sub?.channelUrl ?? 'https://www.youtube.com/channel/$id',
      thumbnailUrl: thumbnails[id],
      commentCount: commentCount,
      liveChatCount: liveChatCount,
    );
  }).toList();

  // Most interactions first; items with an unknown channel always last.
  channels.sort((a, b) {
    if (a.isUnknown != b.isUnknown) return a.isUnknown ? 1 : -1;
    return b.totalInteractions.compareTo(a.totalInteractions);
  });
  return channels;
}

Channel _unknownChannel(int commentCount, int liveChatCount) => Channel(
  channelId: unknownChannelId,
  channelTitle: 'Unknown channel',
  commentCount: commentCount,
  liveChatCount: liveChatCount,
);

@riverpod
Channel? channelById(Ref ref, String channelId) {
  final takeout = ref.watch(viewedTakeoutProvider).value;
  if (takeout == null) return null;

  final commentsByChannel = ref.watch(commentsByChannelProvider);
  final liveChatsByChannel = ref.watch(liveChatsByChannelProvider);
  if (!commentsByChannel.containsKey(channelId) &&
      !liveChatsByChannel.containsKey(channelId)) {
    return null;
  }
  if (channelId == unknownChannelId) {
    return _unknownChannel(
      commentsByChannel[channelId]?.length ?? 0,
      liveChatsByChannel[channelId]?.length ?? 0,
    );
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
