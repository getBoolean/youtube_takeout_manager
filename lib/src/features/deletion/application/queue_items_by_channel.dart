import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import '../domain/deletion_queue_item.dart';
import 'viewed_queue_items.dart';

part 'queue_items_by_channel.g.dart';

/// The channel each queued comment or live chat was posted on, by item ID,
/// grouped the same way as the channel lists. Items whose channel is
/// unknown, or that are no longer in the takeout, are missing.
@riverpod
Map<String, String> queuedItemChannelIds(Ref ref) {
  final queue = ref.watch(viewedQueueItemsProvider);
  if (queue.isEmpty) return const {};

  final queued = {for (final i in queue) (i.itemType, i.itemId)};
  // Not the items' own channelId: that's the author's channel. Items whose
  // channel is unknown are left out, so they group with items no longer in
  // the takeout.
  return {
    for (final kind in QueueItemKind.values)
      for (final MapEntry(key: channelId, value: items)
          in ref.watch(interactionsByChannelProvider(kind)).entries)
        if (channelId != unknownChannelId)
          for (final item in items)
            if (queued.contains((kind, item.id))) item.id: channelId,
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
