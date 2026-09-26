import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/auth_state.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deletion_queue_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/youtube_deletion_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
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

  group('channels', () {
    DeletionQueueItem owned(
      String itemId,
      String? channel, {
      DeletionItemStatus status = DeletionItemStatus.pending,
    }) => _item(itemId, status).copyWith(authorChannelId: channel);

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('queued items remember the channel that wrote them', () async {
      final c = container();
      await c
          .read(deletionQueueProvider.notifier)
          .enqueue(
            const DeletionTargets(commentSnippets: {'c1': 'hi'}),
            authorChannelId: 'UCa',
          );

      final saved = await container().read(deletionQueueProvider.future);
      expect(saved.single.authorChannelId, 'UCa');
    });

    test('items saved before channels were tracked still load', () async {
      final c = container();
      await c.read(deletionQueueRepositoryProvider).saveQueue([
        _item('old', DeletionItemStatus.pending),
      ]);

      final loaded = await container().read(deletionQueueProvider.future);
      expect(loaded.single.authorChannelId, isNull);
    });

    test("pending items are one channel's only", () async {
      final c = container();
      await c.read(deletionQueueRepositoryProvider).saveQueue([
        owned('a', 'UCa'),
        owned('b', 'UCb'),
        owned('aq', 'UCa', status: DeletionItemStatus.quotaExceeded),
        owned('unknown', null),
      ]);
      await c.read(deletionQueueProvider.future);

      final pending = c
          .read(deletionQueueProvider.notifier)
          .pendingItemsFor('UCa');
      expect(pending.map((i) => i.itemId), ['a', 'aq']);
    });

    test('fills in the channel of items saved before it was tracked', () async {
      final c = container();
      await c.read(deletionQueueRepositoryProvider).saveQueue([
        _item('c1', DeletionItemStatus.pending),
        _item('l1', DeletionItemStatus.pending, kind: QueueItemKind.liveChat),
        _item('unmatched', DeletionItemStatus.pending),
        owned('mine', 'UCa'),
      ]);
      await c.read(deletionQueueProvider.future);

      await c
          .read(deletionQueueProvider.notifier)
          .assignMissingChannels(
            commentAuthors: {'c1': 'UCa', 'mine': 'UCb'},
            liveChatAuthors: {'l1': 'UCb', 'c1': 'UCwrongKind'},
          );

      final saved = {
        for (final i in await container().read(deletionQueueProvider.future))
          i.itemId: i.authorChannelId,
      };
      expect(saved, {
        'c1': 'UCa',
        'l1': 'UCb',
        'unmatched': null,
        // Already had a channel.
        'mine': 'UCa',
      });
    });

    test('removes items no takeout matched that are still to do', () async {
      final c = container();
      await c.read(deletionQueueRepositoryProvider).saveQueue([
        owned('old', null),
        owned('old-done', null, status: DeletionItemStatus.succeeded),
        owned('mine', 'UCa'),
      ]);
      await c.read(deletionQueueProvider.future);

      await c.read(deletionQueueProvider.notifier).removeUnassigned();

      expect(
        [
          for (final i in await container().read(deletionQueueProvider.future))
            i.itemId,
        ],
        ['old-done', 'mine'],
      );
    });

    test("retrying and clearing touch one channel's items", () async {
      final c = container();
      await c.read(deletionQueueRepositoryProvider).saveQueue([
        owned('af', 'UCa', status: DeletionItemStatus.failed),
        owned('bf', 'UCb', status: DeletionItemStatus.failed),
        owned('ad', 'UCa', status: DeletionItemStatus.succeeded),
        owned('bd', 'UCb', status: DeletionItemStatus.succeeded),
        owned('unknown-done', null, status: DeletionItemStatus.succeeded),
      ]);
      await c.read(deletionQueueProvider.future);
      final notifier = c.read(deletionQueueProvider.notifier);

      await notifier.retryFailed(channelId: 'UCa');
      await notifier.clearCompleted(channelId: 'UCa');

      final saved = {
        for (final i in await container().read(deletionQueueProvider.future))
          i.itemId: i.status,
      };
      expect(saved, {
        'af': DeletionItemStatus.pending,
        'bf': DeletionItemStatus.failed,
        'bd': DeletionItemStatus.succeeded,
      });
    });

    test("deleting via the API never sends another channel's items", () async {
      final deleted = <String>[];
      final c = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_SignedIn.new),
          googleAuthRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          youtubeDeletionRepositoryProvider.overrideWithValue(
            _RecordingDeletions(deleted),
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(deletionQueueRepositoryProvider).saveQueue([
        owned('b1', 'UCb'),
        owned('a1', 'UCa'),
        owned('unknown', null),
        owned('a2', 'UCa'),
      ]);
      await c.read(deletionQueueProvider.future);

      await c
          .read(deletionQueueProvider.notifier)
          .processPendingViaYoutubeApi(channelId: 'UCa');

      expect(deleted, ['a1', 'a2']);
      final statuses = {
        for (final i in await c.read(deletionQueueProvider.future))
          i.itemId: i.status,
      };
      expect(statuses['b1'], DeletionItemStatus.pending);
      expect(statuses['unknown'], DeletionItemStatus.pending);
    });
  });
}

class _SignedIn extends AuthNotifier {
  @override
  AuthState? build() => const AuthState(accessToken: 'token');
}

class _FakeAuthRepository extends GoogleAuthRepository {
  @override
  http.Client getAuthenticatedClient(String accessToken) => http.Client();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingDeletions extends YoutubeDeletionRepository {
  final List<String> deleted;

  _RecordingDeletions(this.deleted);

  @override
  Future<({bool succeeded, bool quotaExceeded, String? error})> deleteItem(
    http.Client client,
    String itemId,
  ) async {
    deleted.add(itemId);
    return (succeeded: true, quotaExceeded: false, error: null);
  }
}
