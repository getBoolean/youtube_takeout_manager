import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/service/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/service/video_providers.dart';
import '../model/live_chat.dart';

part 'live_chat_providers.g.dart';

@riverpod
List<LiveChat> allLiveChats(Ref ref) {
  return ref.watch(takeoutProvider).value?.liveChats ?? [];
}

@Riverpod(keepAlive: true)
Map<String, List<LiveChat>> liveChatsByChannel(Ref ref) {
  final liveChats = ref.watch(allLiveChatsProvider);
  final videoMetadata = ref.watch(videoMetadataProvider).value ?? {};
  final grouped = <String, List<LiveChat>>{};
  for (final chat in liveChats) {
    final video = chat.videoId != null ? videoMetadata[chat.videoId] : null;
    if (video == null) continue;
    grouped.putIfAbsent(video.channelId, () => []).add(chat);
  }
  return grouped;
}

@riverpod
List<LiveChat> channelLiveChats(Ref ref, String channelId) {
  final byChannel = ref.watch(liveChatsByChannelProvider);
  final chats = byChannel[channelId] ?? [];
  return chats..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

@riverpod
class LiveChatSearchQuery extends _$LiveChatSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}
