import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deletion_queue_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';

void main() {
  ProviderContainer container() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('marking comments deleted at the same time keeps every ID', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    final notifier = c.read(deletedCommentIdsProvider.notifier);
    await c.read(deletedCommentIdsProvider.future);

    await Future.wait([
      notifier.markDeleted({'a'}),
      notifier.markDeleted({'b'}),
    ]);

    expect(await c.read(deletedCommentIdsProvider.future), {'a', 'b'});
    expect(await container().read(deletedCommentIdsProvider.future), {
      'a',
      'b',
    });
  });

  test('marking live chats deleted at the same time keeps every ID', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    final notifier = c.read(deletedLiveChatIdsProvider.notifier);
    await c.read(deletedLiveChatIdsProvider.future);

    await Future.wait([
      notifier.markDeleted({'a'}),
      notifier.markDeleted({'b'}),
    ]);

    expect(await c.read(deletedLiveChatIdsProvider.future), {'a', 'b'});
    expect(await container().read(deletedLiveChatIdsProvider.future), {
      'a',
      'b',
    });
  });
  test('bulk deletes leave out deleted, queued and failed items', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    DeletionQueueItem item(
      String id,
      DeletionItemStatus status, [
      QueueItemKind kind = QueueItemKind.comment,
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
      item('chat', DeletionItemStatus.pending, QueueItemKind.liveChat),
    ]);
    await c.read(deletedCommentIdsProvider.notifier).markDeleted({'deleted'});
    await c.read(deletionQueueProvider.future);

    expect(c.read(excludedFromDeletionCommentIdsProvider), {
      'deleted',
      'pending',
      'running',
      'failed',
      'quota',
    });
    expect(c.read(excludedFromDeletionLiveChatIdsProvider), {'chat'});
  });

  test('items the quota stopped show as queued, as in the queue', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    await c.read(deletionQueueRepositoryProvider).saveQueue([
      for (final (id, status, kind) in [
        ('quota', DeletionItemStatus.quotaExceeded, QueueItemKind.comment),
        ('failed', DeletionItemStatus.failed, QueueItemKind.comment),
        ('chat', DeletionItemStatus.quotaExceeded, QueueItemKind.liveChat),
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

    expect(c.read(queuedCommentIdsProvider), {'quota'});
    expect(c.read(failedCommentIdsProvider), {'failed'});
    expect(c.read(queuedLiveChatIdsProvider), {'chat'});
    expect(c.read(failedLiveChatIdsProvider), isEmpty);
  });
}
