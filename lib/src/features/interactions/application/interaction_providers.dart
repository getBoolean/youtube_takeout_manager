import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import '../domain/interaction.dart';
import '../domain/queue_item_kind.dart';

part 'interaction_providers.g.dart';

/// The viewed takeout's comments or live chats.
@riverpod
List<Interaction> allInteractions(Ref ref, QueueItemKind kind) {
  final takeout = ref.watch(viewedTakeoutProvider).value;
  return switch (kind) {
    QueueItemKind.comment => takeout?.comments ?? [],
    QueueItemKind.liveChat => takeout?.liveChats ?? [],
  };
}

/// [kind]'s items by the channel their video is on. Items whose video's
/// channel isn't known are kept under [unknownChannelId].
@Riverpod(keepAlive: true)
Map<String, List<Interaction>> interactionsByChannel(
  Ref ref,
  QueueItemKind kind,
) {
  final items = ref.watch(allInteractionsProvider(kind));
  final videoMetadata = ref.watch(videoMetadataProvider).value ?? {};
  final grouped = <String, List<Interaction>>{};
  for (final item in items) {
    final video = item.videoId != null ? videoMetadata[item.videoId] : null;
    grouped
        .putIfAbsent(video?.channelId ?? unknownChannelId, () => [])
        .add(item);
  }
  return grouped;
}

/// [kind]'s items on [channelId]'s videos, newest first.
@riverpod
List<Interaction> channelInteractions(
  Ref ref,
  QueueItemKind kind,
  String channelId,
) {
  final byChannel = ref.watch(interactionsByChannelProvider(kind));
  final items = byChannel[channelId] ?? const [];
  return [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
