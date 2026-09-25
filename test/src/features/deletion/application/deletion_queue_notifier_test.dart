import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deletion_queue_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';

DeletionQueueItem _item(
  String itemId,
  DeletionItemStatus status, {
  QueueItemKind kind = QueueItemKind.comment,
}) => DeletionQueueItem(
  id: '${kind.name}-$itemId',
  itemId: itemId,
  itemType: kind,
  status: status,
  createdAt: DateTime.utc(2026),
);

void main() {
  ProviderContainer container() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  Future<List<String>> queueIds(ProviderContainer c) async => [
    for (final i in await c.read(deletionQueueProvider.future)) i.id,
  ];

  test('dropUnprocessed removes waiting and failed entries only', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    await c.read(deletionQueueRepositoryProvider).saveQueue([
      _item('pending', DeletionItemStatus.pending),
      _item('failed', DeletionItemStatus.failed),
      _item('quota', DeletionItemStatus.quotaExceeded),
      _item('done', DeletionItemStatus.succeeded),
      _item('running', DeletionItemStatus.inProgress),
      _item('other', DeletionItemStatus.pending),
      _item(
        'pending',
        DeletionItemStatus.pending,
        kind: QueueItemKind.liveChat,
      ),
    ]);

    await c.read(deletionQueueProvider.notifier).dropUnprocessed({
      'pending',
      'failed',
      'quota',
      'done',
      'running',
    }, QueueItemKind.comment);

    const kept = [
      'comment-done',
      'comment-running',
      'comment-other',
      'liveChat-pending',
    ];
    expect(await queueIds(c), kept);
    expect(await queueIds(container()), kept);
  });
  test('dropping entries at the same time keeps every drop', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    await c.read(deletionQueueRepositoryProvider).saveQueue([
      _item('a', DeletionItemStatus.pending),
      _item('b', DeletionItemStatus.pending),
      _item('c', DeletionItemStatus.pending),
    ]);
    final notifier = c.read(deletionQueueProvider.notifier);
    await c.read(deletionQueueProvider.future);

    await Future.wait([
      notifier.dropUnprocessed({'a'}, QueueItemKind.comment),
      notifier.dropUnprocessed({'b'}, QueueItemKind.comment),
    ]);

    expect(await queueIds(c), ['comment-c']);
    expect(await queueIds(container()), ['comment-c']);
  });
}
