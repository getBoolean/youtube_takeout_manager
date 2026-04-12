import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/channel.dart';
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

  final videoMetadata = ref.watch(videoMetadataProvider);

  // Pre-build channelId → title map from video metadata for O(1) lookups
  final channelTitlesFromVideos = <String, String>{};
  for (final video in videoMetadata.values) {
    if (video.channelTitle != null &&
        !channelTitlesFromVideos.containsKey(video.channelId)) {
      channelTitlesFromVideos[video.channelId] = video.channelTitle!;
    }
  }

  final channels = channelIds.map((id) {
    final sub = subscriptions[id];
    final channelTitle = sub?.channelTitle ?? channelTitlesFromVideos[id];
    return Channel(
      channelId: id,
      channelTitle: channelTitle,
      channelUrl: sub?.channelUrl ?? 'https://www.youtube.com/channel/$id',
      commentCount: commentsByChannel[id]?.length ?? 0,
      liveChatCount: liveChatsByChannel[id]?.length ?? 0,
    );
  }).toList();

  // Sort by total interactions descending
  channels.sort((a, b) => b.totalInteractions.compareTo(a.totalInteractions));
  return channels;
}
