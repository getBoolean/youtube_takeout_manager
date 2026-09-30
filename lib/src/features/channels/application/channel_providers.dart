import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../data/channel_cache_repository.dart';
import '../data/channel_details_repository.dart';
import '../domain/channel_details.dart';
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
  Future<Map<String, String>> build() =>
      ref.watch(channelCacheRepositoryProvider).loadCachedThumbnails();

  /// Adds fetched pictures by channel ID, once the saved ones are in so
  /// they don't replace these. Unreadable saved ones count as none.
  Future<void> add(Map<String, String> thumbnails) async {
    await future.catchError((Object _) => const <String, String>{});
    state = AsyncData({...?state.value, ...thumbnails});
  }

  /// Keeps the pictures on this device.
  Future<void> persist() =>
      _cacheRepository.saveThumbnails(state.value ?? const {});

  /// Forgets every picture, here and on this device, so they're fetched
  /// again.
  Future<void> clear() async {
    await future.catchError((Object _) => const <String, String>{});
    await _cacheRepository.clearThumbnails();
    state = const AsyncData({});
  }
}

/// Channels' topics and descriptions, by channel ID, kept on this device.
/// Fetched with their pictures by `ChannelThumbnailFetcher`.
@Riverpod(keepAlive: true)
class ChannelDetailsNotifier extends _$ChannelDetailsNotifier {
  ChannelDetailsRepository get _repository =>
      ref.read(channelDetailsRepositoryProvider);

  @override
  Future<Map<String, ChannelDetails>> build() =>
      ref.watch(channelDetailsRepositoryProvider).load();

  /// Adds fetched details, once the saved ones are in so they don't replace
  /// these. Unreadable saved ones count as none.
  Future<void> add(Map<String, ChannelDetails> details) async {
    if (details.isEmpty) return;
    await future.catchError((Object _) => const <String, ChannelDetails>{});
    state = AsyncData({...?state.value, ...details});
  }

  /// Keeps the details on this device.
  Future<void> persist() => _repository.save(state.value ?? const {});

  /// Forgets every channel's details, here and on this device.
  Future<void> clear() async {
    await future.catchError((Object _) => const <String, ChannelDetails>{});
    await _repository.clear();
    state = const AsyncData({});
  }
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
  final thumbnails = ref.watch(channelThumbnailsProvider).value ?? const {};

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
    thumbnails: ref.watch(channelThumbnailsProvider).value ?? const {},
  );
}
