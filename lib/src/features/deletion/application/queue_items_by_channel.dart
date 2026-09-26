import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import '../domain/deletion_queue_item.dart';
import '../domain/queue_item_kind.dart';
import 'deletion_queue_notifier.dart';

part 'queue_items_by_channel.g.dart';

/// The channel each queued comment or live chat was posted on, by item ID,
/// grouped the same way as the channel lists. Items whose channel is
/// unknown, or that are no longer in the takeout, are missing.
@riverpod
Map<String, String> queuedItemChannelIds(Ref ref) {
  final queue = ref.watch(deletionQueueProvider).value ?? const [];
  if (queue.isEmpty) return const {};

  final commentIds = <String>{};
  final liveChatIds = <String>{};
  for (final item in queue) {
    (item.itemType == QueueItemKind.comment ? commentIds : liveChatIds).add(
      item.itemId,
    );
  }
  // Not the items' own channelId: that's the author's channel. Items whose
  // channel is unknown are left out, so they group with items no longer in
  // the takeout.
  return {
    for (final MapEntry(key: channelId, value: comments)
        in ref.watch(commentsByChannelProvider).entries)
      if (channelId != unknownChannelId)
        for (final c in comments)
          if (commentIds.contains(c.commentId)) c.commentId: channelId,
    for (final MapEntry(key: channelId, value: liveChats)
        in ref.watch(liveChatsByChannelProvider).entries)
      if (channelId != unknownChannelId)
        for (final c in liveChats)
          if (liveChatIds.contains(c.liveChatId)) c.liveChatId: channelId,
  };
}

/// Queue items posted on one channel, or on an unknown one when [channelId]
/// is null.
class QueueChannelGroup {
  final String? channelId;
  final List<DeletionQueueItem> items;

  const QueueChannelGroup(this.channelId, this.items);
}

/// Groups [items] by channel, keeping queue order within each group.
///
/// [firstChannelId]'s group comes first, then the rest ordered by
/// [channelName], then items whose channel is unknown.
List<QueueChannelGroup> groupQueueItemsByChannel(
  Iterable<DeletionQueueItem> items, {
  required Map<String, String> channelIds,
  required String Function(String channelId) channelName,
  String? firstChannelId,
}) {
  final byChannel = <String?, List<DeletionQueueItem>>{};
  for (final item in items) {
    (byChannel[channelIds[item.itemId]] ??= []).add(item);
  }

  int rank(String? id) => id == null
      ? 2
      : id == firstChannelId
      ? 0
      : 1;

  final keys = byChannel.keys.toList()
    ..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0 || a == null || b == null) return byRank;
      return channelName(
        a,
      ).toLowerCase().compareTo(channelName(b).toLowerCase());
    });
  return [for (final key in keys) QueueChannelGroup(key, byChannel[key]!)];
}
