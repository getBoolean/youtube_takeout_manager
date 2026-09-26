import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import '../domain/live_chat.dart';

part 'live_chat_providers.g.dart';

@riverpod
List<LiveChat> allLiveChats(Ref ref) {
  return ref.watch(takeoutProvider).value?.liveChats ?? [];
}

/// Live chats by the channel their video is on. Live chats whose video's
/// channel isn't known are kept under [unknownChannelId].
@Riverpod(keepAlive: true)
Map<String, List<LiveChat>> liveChatsByChannel(Ref ref) {
  final liveChats = ref.watch(allLiveChatsProvider);
  final videoMetadata = ref.watch(videoMetadataProvider).value ?? {};
  final grouped = <String, List<LiveChat>>{};
  for (final chat in liveChats) {
    final video = chat.videoId != null ? videoMetadata[chat.videoId] : null;
    grouped
        .putIfAbsent(video?.channelId ?? unknownChannelId, () => [])
        .add(chat);
  }
  return grouped;
}

@riverpod
List<LiveChat> channelLiveChats(Ref ref, String channelId) {
  final byChannel = ref.watch(liveChatsByChannelProvider);
  final chats = byChannel[channelId] ?? [];
  return chats..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
