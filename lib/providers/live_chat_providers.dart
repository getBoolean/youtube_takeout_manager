import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/live_chat.dart';
import 'takeout_providers.dart';

part 'live_chat_providers.g.dart';

@riverpod
List<LiveChat> allLiveChats(Ref ref) {
  return ref.watch(takeoutProvider)?.liveChats ?? [];
}

@riverpod
Map<String, List<LiveChat>> liveChatsByChannel(Ref ref) {
  final liveChats = ref.watch(allLiveChatsProvider);
  final grouped = <String, List<LiveChat>>{};
  for (final chat in liveChats) {
    grouped.putIfAbsent(chat.channelId, () => []).add(chat);
  }
  return grouped;
}

@riverpod
List<LiveChat> channelLiveChats(Ref ref, String channelId) {
  final byChannel = ref.watch(liveChatsByChannelProvider);
  final chats = byChannel[channelId] ?? [];
  return chats..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
