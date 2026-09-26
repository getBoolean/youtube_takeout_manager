import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_counts.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_items_by_channel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/viewed_queue_items.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

DeletionQueueItem _item(
  String itemId,
  String? channel, {
  DeletionItemStatus status = DeletionItemStatus.pending,
}) => DeletionQueueItem(
  id: 'q-$itemId',
  itemId: itemId,
  itemType: QueueItemKind.comment,
  status: status,
  createdAt: DateTime.utc(2026),
  authorChannelId: channel,
);

class _Queue extends DeletionQueue {
  @override
  Future<List<DeletionQueueItem>> build() async => [
    _item('a1', 'UCa'),
    _item('a2', 'UCa', status: DeletionItemStatus.succeeded),
    _item('b1', 'UCb'),
    _item('old', null),
    _item('old-done', null, status: DeletionItemStatus.succeeded),
  ];
}

Comment _comment(String id) => Comment(
  commentId: id,
  channelId: 'UCa',
  createdAt: DateTime.utc(2026),
  price: 0,
  rawCommentText: '',
  displayText: '',
);

void main() {
  Future<ProviderContainer> container() async {
    final c = ProviderContainer(
      overrides: [
        deletionQueueProvider.overrideWith(_Queue.new),
        viewedChannelIdProvider.overrideWithValue('UCa'),
        commentsByChannelProvider.overrideWithValue({
          'UCvideo': [_comment('a1'), _comment('b1')],
        }),
        liveChatsByChannelProvider.overrideWithValue(const {}),
      ],
    );
    addTearDown(c.dispose);
    await c.read(deletionQueueProvider.future);
    return c;
  }

  test("the queue shows the viewed channel's items", () async {
    final c = await container();
    expect(c.read(viewedQueueItemsProvider).map((i) => i.itemId), ['a1', 'a2']);
  });

  test(
    'items with no channel yet that are still to do are set apart',
    () async {
      final c = await container();
      expect(c.read(unassignedQueueItemsProvider).map((i) => i.itemId), [
        'old',
      ]);
    },
  );

  test("counts are the viewed channel's", () async {
    final c = await container();
    expect(
      c.read(deletionQueueCountsProvider),
      const DeletionQueueCounts(waiting: 1, done: 1),
    );
  });

  test("groups only the viewed channel's items by channel", () async {
    final c = await container();
    expect(c.read(queuedItemChannelIdsProvider), {'a1': 'UCvideo'});
  });
}
