import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../domain/deletion_queue_item.dart';
import 'deletion_queue_notifier.dart';

part 'viewed_queue_items.g.dart';

/// The queue items written by the viewed channel. Other channels' items wait
/// for their own channel to be viewed, since only its sign-in deletes them.
@riverpod
List<DeletionQueueItem> viewedQueueItems(Ref ref) {
  final channelId = ref.watch(viewedChannelIdProvider);
  if (channelId == null) return const [];
  return [
    for (final i in ref.watch(deletionQueueProvider).value ?? const [])
      if (i.authorChannelId == channelId) i,
  ];
}

/// Items queued before their channel was saved that aren't done yet, and
/// that no loaded takeout has matched to a channel. They're never deleted
/// until one does.
@riverpod
List<DeletionQueueItem> unassignedQueueItems(Ref ref) => [
  for (final i in ref.watch(deletionQueueProvider).value ?? const [])
    if (i.authorChannelId == null && !i.status.isDone) i,
];
