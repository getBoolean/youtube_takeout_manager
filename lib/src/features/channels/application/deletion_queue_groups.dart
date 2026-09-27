import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_filter.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_items_by_channel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/viewed_queue_items.dart';
import 'channel_providers.dart';

part 'deletion_queue_groups.g.dart';

/// The viewed channel's queue items [filter] shows, grouped by the channel
/// they were posted on: [firstChannelId]'s first, then the rest by name,
/// then items whose channel is unknown.
///
/// Here rather than in the deletion feature, which the channels feature
/// depends on, since it orders the groups by channel name.
@riverpod
List<QueueChannelGroup> deletionQueueGroups(
  Ref ref,
  DeletionQueueFilter filter, {
  String? firstChannelId,
}) {
  final visible = [
    for (final item in ref.watch(viewedQueueItemsProvider))
      if (filter.shows(item.status)) item,
  ];
  if (visible.isEmpty) return const [];

  final channelsById = {
    for (final c in ref.watch(channelsProvider)) c.channelId: c,
  };
  return groupQueueItemsByChannel(
    visible,
    channelIds: ref.watch(queuedItemChannelIdsProvider),
    channelName: (id) => channelsById[id]?.channelTitle ?? id,
    firstChannelId: firstChannelId,
  );
}
