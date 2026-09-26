import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_items_by_channel.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';

DeletionQueueItem _item(String itemId) => DeletionQueueItem(
  id: 'q-$itemId',
  itemId: itemId,
  itemType: QueueItemKind.comment,
  status: DeletionItemStatus.pending,
  createdAt: DateTime.utc(2026),
);

const _names = {'UCa': 'alpha', 'UCb': 'Bravo', 'UCc': 'charlie'};

void main() {
  /// Each group as `channel: item ids`.
  List<String> group(List<DeletionQueueItem> items, {String? first}) => [
    for (final g in groupQueueItemsByChannel(
      items,
      channelIds: const {'1': 'UCc', '2': 'UCa', '3': 'UCb', '4': 'UCa'},
      channelName: (id) => _names[id]!,
      firstChannelId: first,
    ))
      '${g.channelId}: ${g.items.map((i) => i.itemId).join(',')}',
  ];

  test('orders channels by name, keeping queue order inside each', () {
    expect(group([_item('1'), _item('2'), _item('3'), _item('4')]), [
      'UCa: 2,4',
      'UCb: 3',
      'UCc: 1',
    ]);
  });

  test('puts the current channel first', () {
    expect(group([_item('1'), _item('2'), _item('3')], first: 'UCc'), [
      'UCc: 1',
      'UCa: 2',
      'UCb: 3',
    ]);
  });

  test('puts items from unknown channels last', () {
    expect(group([_item('gone'), _item('3')]), ['UCb: 3', 'null: gone']);
  });

  test(
    "maps queued items to their video's channel, not the author's",
    () async {
      final container = ProviderContainer(
        overrides: [
          deletionQueueProvider.overrideWith(
            () => _FakeQueue([_item('c1'), _liveChatItem('l1'), _item('gone')]),
          ),
          commentsByChannelProvider.overrideWithValue({
            'UCvideo': [_comment('c1'), _comment('c2')],
          }),
          liveChatsByChannelProvider.overrideWithValue({
            'UCstream': [_liveChat('l1')],
          }),
        ],
      );
      addTearDown(container.dispose);
      await container.read(deletionQueueProvider.future);

      expect(container.read(queuedItemChannelIdsProvider), {
        'c1': 'UCvideo',
        'l1': 'UCstream',
      });
    },
  );

  test(
    'leaves items whose channel is unknown out, so they group last',
    () async {
      final container = ProviderContainer(
        overrides: [
          deletionQueueProvider.overrideWith(
            () => _FakeQueue([_item('c1'), _item('no-details')]),
          ),
          commentsByChannelProvider.overrideWithValue({
            'UCvideo': [_comment('c1')],
            unknownChannelId: [_comment('no-details')],
          }),
          liveChatsByChannelProvider.overrideWithValue(const {}),
        ],
      );
      addTearDown(container.dispose);
      await container.read(deletionQueueProvider.future);

      expect(container.read(queuedItemChannelIdsProvider), {'c1': 'UCvideo'});
    },
  );
}

class _FakeQueue extends DeletionQueue {
  final List<DeletionQueueItem> items;

  _FakeQueue(this.items);

  @override
  Future<List<DeletionQueueItem>> build() async => items;
}

DeletionQueueItem _liveChatItem(String itemId) => DeletionQueueItem(
  id: 'q-$itemId',
  itemId: itemId,
  itemType: QueueItemKind.liveChat,
  status: DeletionItemStatus.pending,
  createdAt: DateTime.utc(2026),
);

// Authored by the user's own channel, like every takeout item.
Comment _comment(String id) => Comment(
  commentId: id,
  channelId: 'UCme',
  createdAt: DateTime.utc(2026),
  price: 0,
  rawCommentText: '',
  displayText: '',
);

LiveChat _liveChat(String id) => LiveChat(
  liveChatId: id,
  channelId: 'UCme',
  createdAt: DateTime.utc(2026),
  price: 0,
  rawText: '',
  displayText: '',
);
