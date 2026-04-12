import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/channel.dart';
import 'comment_providers.dart';
import 'live_chat_providers.dart';
import 'takeout_providers.dart';

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

  final channels = channelIds.map((id) {
    final sub = subscriptions[id];
    return Channel(
      channelId: id,
      channelTitle: sub?.channelTitle,
      channelUrl: sub?.channelUrl,
      commentCount: commentsByChannel[id]?.length ?? 0,
      liveChatCount: liveChatsByChannel[id]?.length ?? 0,
    );
  }).toList();

  // Sort by total interactions descending
  channels.sort((a, b) => b.totalInteractions.compareTo(a.totalInteractions));
  return channels;
}
