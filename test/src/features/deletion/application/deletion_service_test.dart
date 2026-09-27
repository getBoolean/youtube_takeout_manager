import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_service.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/script_deletion_ids.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deletion_queue_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/my_activity_results.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';

DeletionQueueItem _item(
  String itemId, {
  String channel = 'UCme',
  DeletionItemStatus status = DeletionItemStatus.pending,
  QueueItemKind kind = QueueItemKind.comment,
}) => DeletionQueueItem(
  id: 'q-$itemId',
  itemId: itemId,
  itemType: kind,
  status: status,
  displayTextSnippet: 'text $itemId',
  createdAt: DateTime.utc(2026),
  authorChannelId: channel,
);

LiveChat _chat(String id, String text) => LiveChat(
  liveChatId: id,
  channelId: 'UCme',
  createdAt: DateTime.utc(2026),
  price: 0,
  rawText: text,
  displayText: text,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> start(
    List<DeletionQueueItem> items, {
    String? viewed = 'UCme',
    List<LiveChat> liveChats = const [],
  }) async {
    final c = ProviderContainer(
      overrides: [
        viewedChannelIdProvider.overrideWithValue(viewed),
        viewedTakeoutProvider.overrideWithValue(
          AsyncData(
            TakeoutData(
              comments: const [],
              liveChats: liveChats,
              subscriptionsByChannelId: const {},
            ),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(deletionQueueRepositoryProvider).saveQueue(items);
    await c.read(deletionQueueProvider.future);
    await c.read(deletedIdsProvider.future);
    return c;
  }

  DeletionService service(ProviderContainer c) =>
      c.read(deletionServiceProvider.notifier);

  Future<Map<String, DeletionQueueItem>> queue(ProviderContainer c) async => {
    for (final i in await c.read(deletionQueueProvider.future)) i.itemId: i,
  };

  group('My Activity results', () {
    test('mark what was deleted, as its own kind, and record failures in '
        'the queue', () async {
      final c = await start([
        _item('c1'),
        _item('l1', kind: QueueItemKind.liveChat),
        _item('c2'),
        _item('c3'),
      ]);
      const targets = DeletionTargets(
        commentSnippets: {'c1': null, 'c2': null},
        liveChatSnippets: {'l1': null},
      );

      await service(c).recordMyActivityResults(
        targets,
        const MyActivityResults(
          deleted: {'c1', 'l1', 'not-a-target'},
          failed: [(id: 'c2', error: 'Not found')],
        ),
      );

      final deleted = await c.read(deletedIdsProvider.future);
      expect(deleted[QueueItemKind.comment], {'c1'});
      expect(deleted[QueueItemKind.liveChat], {'l1'});
      final items = await queue(c);
      expect(items['c1']!.status, DeletionItemStatus.succeeded);
      expect(items['l1']!.status, DeletionItemStatus.succeeded);
      expect(items['c2']!.status, DeletionItemStatus.failed);
      expect(items['c2']!.errorMessage, 'Not found');
      expect(items['c3']!.status, DeletionItemStatus.pending);
    });

    test("leaves queued items outside the targets alone, so the queue and "
        'deleted items agree', () async {
      // E.g. older results pasted again after Retry Failed narrowed them.
      final c = await start([_item('c1'), _item('stray'), _item('stray2')]);

      await service(c).recordMyActivityResults(
        const DeletionTargets(commentSnippets: {'c1': null}),
        const MyActivityResults(
          deleted: {'c1', 'stray'},
          failed: [(id: 'stray2', error: 'Nope')],
        ),
      );

      expect((await c.read(deletedIdsProvider.future))[QueueItemKind.comment], {
        'c1',
      });
      final items = await queue(c);
      expect(items['c1']!.status, DeletionItemStatus.succeeded);
      expect(items['stray']!.status, DeletionItemStatus.pending);
      expect(items['stray2']!.status, DeletionItemStatus.pending);
      expect(items['stray2']!.errorMessage, isNull);
    });

    test('with nothing deleted, marks nothing', () async {
      final c = await start([_item('c1')]);

      await service(c).recordMyActivityResults(
        const DeletionTargets(commentSnippets: {'c1': null}),
        const MyActivityResults(
          deleted: {},
          failed: [(id: 'c1', error: 'Nope')],
        ),
      );

      expect(
        (await c.read(deletedIdsProvider.future)).values,
        everyElement(isEmpty),
      );
      expect((await queue(c))['c1']!.status, DeletionItemStatus.failed);
    });
  });

  group('queueing', () {
    test("queues items as the viewed channel's", () async {
      final c = await start([]);

      final queued = await service(
        c,
      ).queue(const DeletionTargets(commentSnippets: {'c1': 'hi'}));

      expect(queued, isTrue);
      final item = (await queue(c))['c1']!;
      expect(item.authorChannelId, 'UCme');
      expect(item.displayTextSnippet, 'hi');
    });

    test('queues nothing while no channel is viewed', () async {
      final c = await start([], viewed: null);

      final queued = await service(
        c,
      ).queue(const DeletionTargets(commentSnippets: {'c1': 'hi'}));

      expect(queued, isFalse);
      expect(await queue(c), isEmpty);
    });
  });

  test('removing locally only marks items deleted', () async {
    final c = await start([_item('c1')]);

    await service(c).removeLocally(
      const DeletionTargets(
        commentSnippets: {'c1': null},
        liveChatSnippets: {'l1': null},
      ),
    );

    final deleted = await c.read(deletedIdsProvider.future);
    expect(deleted[QueueItemKind.comment], {'c1'});
    expect(deleted[QueueItemKind.liveChat], {'l1'});
    expect((await queue(c))['c1']!.status, DeletionItemStatus.pending);
  });

  group('waiting items', () {
    test("are the viewed channel's that the next Delete takes, with the "
        'live chats that may be membership events', () async {
      final c = await start(
        [
          _item('c1'),
          _item('lq', kind: QueueItemKind.liveChat),
          _item('l2', kind: QueueItemKind.liveChat),
          _item('cq', status: DeletionItemStatus.quotaExceeded),
          _item('running', status: DeletionItemStatus.inProgress),
          _item('failed', status: DeletionItemStatus.failed),
          _item('other', channel: 'UCother'),
        ],
        liveChats: [_chat('lq', ' '), _chat('l2', 'hello')],
      );

      final waiting = service(c).waiting()!;

      expect(waiting.channelId, 'UCme');
      expect(waiting.targets.commentIds, {'c1', 'cq'});
      expect(waiting.targets.liveChatIds, {'lq', 'l2'});
      expect(waiting.possibleMembershipEvents, 1);
    });

    test('are none when nothing waits', () async {
      final c = await start([
        _item('done', status: DeletionItemStatus.succeeded),
        _item('other', channel: 'UCother'),
      ]);

      expect(service(c).waiting(), isNull);
    });
  });

  test('the My Activity script is handed its items', () async {
    final c = await start([]);
    c.listen(scriptDeletionIdsProvider, (_, _) {});
    const targets = DeletionTargets(
      commentSnippets: {'c1': null},
      liveChatSnippets: {'l1': null},
    );

    service(c).useMyActivityScript(targets);

    expect(c.read(scriptDeletionIdsProvider).commentIds, {'c1'});
    expect(c.read(scriptDeletionIdsProvider).liveChatIds, {'l1'});
  });
}
