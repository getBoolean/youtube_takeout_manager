import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
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

  final commentsByChannel = ref.watch(
    interactionsByChannelProvider(QueueItemKind.comment),
  );
  final liveChatsByChannel = ref.watch(
    interactionsByChannelProvider(QueueItemKind.liveChat),
  );
  final subscriptions = takeout.subscriptionsByChannelId;

  // Collect all unique channel IDs from both comments and live chats
  final channelIds = <String>{
    ...commentsByChannel.keys,
    ...liveChatsByChannel.keys,
  };

  final titlesFromVideos = ref.watch(channelTitlesFromVideosProvider);
  final thumbnails = ref.watch(channelThumbnailsProvider);

  final channels = [
    for (final id in channelIds)
      _channelOf(
        id,
        commentCount: commentsByChannel[id]?.length ?? 0,
        liveChatCount: liveChatsByChannel[id]?.length ?? 0,
        subscriptions: subscriptions,
        titlesFromVideos: titlesFromVideos,
        thumbnails: thumbnails,
      ),
  ];

  // Most interactions first; items with an unknown channel always last.
  channels.sort((a, b) {
    if (a.isUnknown != b.isUnknown) return a.isUnknown ? 1 : -1;
    return b.totalInteractions.compareTo(a.totalInteractions);
  });
  return channels;
}

/// [id]'s channel: named by the takeout's [subscriptions] or else its videos,
/// and pictured once its picture is fetched.
Channel _channelOf(
  String id, {
  required int commentCount,
  required int liveChatCount,
  required Map<String, Subscription> subscriptions,
  required Map<String, String> titlesFromVideos,
  required Map<String, String> thumbnails,
}) {
  if (id == unknownChannelId) {
    return Channel(
      channelId: unknownChannelId,
      channelTitle: 'Unknown channel',
      commentCount: commentCount,
      liveChatCount: liveChatCount,
    );
  }
  final sub = subscriptions[id];
  return Channel(
    channelId: id,
    channelTitle: sub?.channelTitle ?? titlesFromVideos[id],
    channelUrl: sub?.channelUrl ?? 'https://www.youtube.com/channel/$id',
    thumbnailUrl: thumbnails[id],
    commentCount: commentCount,
    liveChatCount: liveChatCount,
  );
}

@riverpod
Channel? channelById(Ref ref, String channelId) {
  final takeout = ref.watch(viewedTakeoutProvider).value;
  if (takeout == null) return null;

  final commentsByChannel = ref.watch(
    interactionsByChannelProvider(QueueItemKind.comment),
  );
  final liveChatsByChannel = ref.watch(
    interactionsByChannelProvider(QueueItemKind.liveChat),
  );
  if (!commentsByChannel.containsKey(channelId) &&
      !liveChatsByChannel.containsKey(channelId)) {
    return null;
  }
  return _channelOf(
    channelId,
    commentCount: commentsByChannel[channelId]?.length ?? 0,
    liveChatCount: liveChatsByChannel[channelId]?.length ?? 0,
    subscriptions: takeout.subscriptionsByChannelId,
    titlesFromVideos: ref.watch(channelTitlesFromVideosProvider),
    thumbnails: ref.watch(channelThumbnailsProvider),
  );
}
