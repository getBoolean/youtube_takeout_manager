import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/channel.dart';
import 'comment_providers.dart';
import 'live_chat_providers.dart';
import 'takeout_providers.dart';
import 'video_providers.dart';

part 'channel_providers.g.dart';

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

  final channels = channelIds.map((id) {
    final sub = subscriptions[id];
    // Try subscription title first, then fall back to video metadata
    var channelTitle = sub?.channelTitle;
    if (channelTitle == null) {
      for (final video in videoMetadata.values) {
        if (video.channelId == id && video.channelTitle != null) {
          channelTitle = video.channelTitle;
          break;
        }
      }
    }
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
