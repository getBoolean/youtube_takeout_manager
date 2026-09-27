import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deleted_ids_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deletion_queue_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

const _comment = QueueItemKind.comment;
const _liveChat = QueueItemKind.liveChat;

/// Storage whose reads fail, as when saved data can't be read.
class _UnreadableIds extends DeletedIdsRepository {
  _UnreadableIds() : super(KvStorageService());

  @override
  Future<Set<String>> loadDeletedIds(QueueItemKind kind) =>
      Future.error(StateError('unreadable'));
}

void main() {
  ProviderContainer container() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  for (final kind in QueueItemKind.values) {
    test(
      'marking ${kind.name}s deleted at the same time keeps every ID',
      () async {
        SharedPreferences.setMockInitialValues({});
        final c = container();
        final notifier = c.read(deletedIdsProvider.notifier);
        await c.read(deletedIdsProvider.future);

        await Future.wait([
          notifier.markDeleted(
            DeletionTargets.ids({
              kind: {'a'},
            }),
          ),
          notifier.markDeleted(
            DeletionTargets.ids({
              kind: {'b'},
            }),
          ),
        ]);

        expect((await c.read(deletedIdsProvider.future))[kind], {'a', 'b'});
        expect((await container().read(deletedIdsProvider.future))[kind], {
          'a',
          'b',
        });
      },
    );
  }

  test('marking comments and live chats deleted at once files each under '
      'its kind, keeping the IDs saved before', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    final kv = c.read(kvStorageServiceProvider);
    // The keys earlier versions saved under.
    await kv.setStringList('deleted_comment_ids', ['saved-comment']);
    await kv.setStringList('deleted_live_chat_ids', ['saved-chat']);

    await c
        .read(deletedIdsProvider.notifier)
        .markDeleted(
          const DeletionTargets(
            commentSnippets: {'comment': 'hi'},
            liveChatSnippets: {'chat': null},
          ),
        );

    expect(await c.read(deletedIdsProvider.future), {
      _comment: {'saved-comment', 'comment'},
      _liveChat: {'saved-chat', 'chat'},
    });
    expect(
      await kv.getStringList('deleted_comment_ids'),
      unorderedEquals(['saved-comment', 'comment']),
    );
    expect(
      await kv.getStringList('deleted_live_chat_ids'),
      unorderedEquals(['saved-chat', 'chat']),
    );
  });

  test("marking nothing deleted doesn't wait for the saved IDs", () async {
    final c = ProviderContainer(
      overrides: [
        deletedIdsRepositoryProvider.overrideWithValue(_UnreadableIds()),
      ],
    );
    addTearDown(c.dispose);
    c.listen(deletedIdsProvider, (_, _) {});

    await c
        .read(deletedIdsProvider.notifier)
        .markDeleted(const DeletionTargets());

    expect(c.read(deletedIdsProvider).hasError, isTrue);
  });

  test('bulk deletes leave out deleted, queued and failed items', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    DeletionQueueItem item(
      String id,
      DeletionItemStatus status, [
      QueueItemKind kind = _comment,
    ]) => DeletionQueueItem(
      id: 'q-$id',
      itemId: id,
      itemType: kind,
      status: status,
      createdAt: DateTime.utc(2026),
    );
    await c.read(deletionQueueRepositoryProvider).saveQueue([
      item('pending', DeletionItemStatus.pending),
      item('running', DeletionItemStatus.inProgress),
      item('failed', DeletionItemStatus.failed),
      item('quota', DeletionItemStatus.quotaExceeded),
      item('done', DeletionItemStatus.succeeded),
      item('chat', DeletionItemStatus.pending, _liveChat),
    ]);
    await c
        .read(deletedIdsProvider.notifier)
        .markDeleted(
          DeletionTargets.ids({
            _comment: {'deleted'},
          }),
        );
    await c.read(deletionQueueProvider.future);

    expect(c.read(excludedFromDeletionIdsProvider), {
      _comment: {'deleted', 'pending', 'running', 'failed', 'quota'},
      _liveChat: {'chat'},
    });
  });

  test('items the quota stopped show as queued, as in the queue', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    await c.read(deletionQueueRepositoryProvider).saveQueue([
      for (final (id, status, kind) in [
        ('quota', DeletionItemStatus.quotaExceeded, _comment),
        ('failed', DeletionItemStatus.failed, _comment),
        ('chat', DeletionItemStatus.quotaExceeded, _liveChat),
      ])
        DeletionQueueItem(
          id: 'q-$id',
          itemId: id,
          itemType: kind,
          status: status,
          createdAt: DateTime.utc(2026),
        ),
    ]);
    await c.read(deletionQueueProvider.future);

    expect(c.read(queuedIdsProvider(_comment)), {'quota'});
    expect(c.read(failedIdsProvider(_comment)), {'failed'});
    expect(c.read(queuedIdsProvider(_liveChat)), {'chat'});
    expect(c.read(failedIdsProvider(_liveChat)), isEmpty);
  });

  test("each kind's statuses come from its own deleted, failed and queued "
      'items', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    await c.read(deletionQueueRepositoryProvider).saveQueue([
      for (final (id, status, kind) in [
        ('quota', DeletionItemStatus.quotaExceeded, _comment),
        ('failed', DeletionItemStatus.failed, _comment),
        ('chat', DeletionItemStatus.failed, _liveChat),
      ])
        DeletionQueueItem(
          id: 'q-$id',
          itemId: id,
          itemType: kind,
          status: status,
          createdAt: DateTime.utc(2026),
        ),
    ]);
    await c.read(deletionQueueProvider.future);
    await c
        .read(deletedIdsProvider.notifier)
        .markDeleted(
          DeletionTargets.ids({
            _liveChat: {'gone'},
          }),
        );

    final comments = c.read(interactionStatusesProvider(_comment));
    final chats = c.read(interactionStatusesProvider(_liveChat));
    expect(comments.of('quota'), InteractionStatus.queued);
    expect(comments.of('failed'), InteractionStatus.failed);
    expect(comments.of('chat'), InteractionStatus.active);
    expect(comments.of('gone'), InteractionStatus.active);
    expect(chats.of('chat'), InteractionStatus.failed);
    expect(chats.of('gone'), InteractionStatus.deleted);
  });

  test("marking comments deleted leaves live chats' statuses be", () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    await c.read(deletedIdsProvider.future);
    await c.read(deletionQueueProvider.future);

    await c
        .read(deletedIdsProvider.notifier)
        .markDeleted(
          DeletionTargets.ids({
            _comment: {'gone'},
          }),
        );
    // Lets dependents rebuild.
    await c.pump();

    expect(
      c.read(interactionStatusesProvider(_comment)).of('gone'),
      InteractionStatus.deleted,
    );
    expect(
      c.read(interactionStatusesProvider(_liveChat)).of('gone'),
      InteractionStatus.active,
    );
  });
}
