import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deletion_queue_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/youtube_deletion_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_outcome.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/quota/data/quota_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

DeletionQueueItem _item(
  String itemId, {
  String? channel = 'UCa',
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

/// How the fake YouTube answers deleting an item.
enum _Answer { deleted, quotaExceeded, signInFailed, failed }

DeletionOutcome _result(_Answer answer) => switch (answer) {
  _Answer.deleted => const Deleted(),
  _Answer.quotaExceeded => const QuotaExceeded('quota gone'),
  _Answer.signInFailed => const SignInFailed(),
  _Answer.failed => const Failed('comment not found'),
};

/// YouTube, answering each item as [answers] says (deleted by default) and
/// recording what was sent. Waits on [gate] before answering, if given.
class _FakeYoutube extends YoutubeDeletionRepository {
  final Map<String, _Answer> answers;
  final sent = <String>[];
  Completer<void>? gate;

  _FakeYoutube([this.answers = const {}]);

  @override
  Future<DeletionOutcome> deleteItem(http.Client client, String itemId) async {
    sent.add(itemId);
    await gate?.future;
    return _result(answers[itemId] ?? _Answer.deleted);
  }
}

class _SignedIn extends AuthNotifier {
  @override
  SignInProfile? build() => const SignInProfile(channelId: 'UCa');
}

class _SignIns extends SignInService {
  final failed = <String>[];

  @override
  void build() {}

  @override
  Future<void> signInFailed(String channelId) async => failed.add(channelId);
}

class _FakeAuthRepository extends GoogleAuthRepository {
  @override
  http.Client getAuthenticatedClient(String channelId) => http.Client();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Today's quota, kept in memory, with room for [deletes] deletes.
class _Quota extends QuotaRepository {
  QuotaState state;

  _Quota(int deletes)
    : state = QuotaState(
        usageByOperation: {
          QuotaOperation.videosList:
              dailyQuotaLimit - deletes * QuotaOperation.deleteCost,
        },
        periodStart: DateTime.now().toUtc(),
      ),
      super(KvStorageService());

  @override
  Future<QuotaState> loadQuotaState() async => state;

  @override
  Future<void> saveQuotaState(QuotaState state) async => this.state = state;
}

void main() {
  late _FakeYoutube youtube;
  late _SignIns signIns;
  late _Quota quota;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> start(
    List<DeletionQueueItem> items, {
    Map<String, _Answer> answers = const {},
    int deletesLeft = 200,
  }) async {
    youtube = _FakeYoutube(answers);
    signIns = _SignIns();
    quota = _Quota(deletesLeft);
    final c = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_SignedIn.new),
        signInServiceProvider.overrideWith(() => signIns),
        googleAuthRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        youtubeDeletionRepositoryProvider.overrideWithValue(youtube),
        quotaRepositoryProvider.overrideWithValue(quota),
      ],
    );
    addTearDown(c.dispose);
    await c.read(deletionQueueRepositoryProvider).saveQueue(items);
    await c.read(deletionQueueProvider.future);
    return c;
  }

  Future<void> process(ProviderContainer c, {String channelId = 'UCa'}) => c
      .read(deletionProcessingProvider.notifier)
      .processPendingViaYoutubeApi(channelId: channelId);

  Future<Map<String, DeletionQueueItem>> queue(ProviderContainer c) async => {
    for (final i in await c.read(deletionQueueProvider.future)) i.itemId: i,
  };

  Future<Map<String, DeletionItemStatus>> statuses(ProviderContainer c) async =>
      {
        for (final MapEntry(:key, :value) in (await queue(c)).entries)
          key: value.status,
      };

  group('each answer', () {
    test('a deleted item is done, counted against the quota and remembered '
        'as deleted', () async {
      final c = await start([
        _item('c1'),
        _item('l1', kind: QueueItemKind.liveChat),
      ]);

      await process(c);

      final items = await queue(c);
      expect(items['c1']!.status, DeletionItemStatus.succeeded);
      expect(items['c1']!.processedAt, isNotNull);
      expect(items['c1']!.errorMessage, isNull);
      expect(items['l1']!.status, DeletionItemStatus.succeeded);
      expect(quota.state.usageFor(QuotaOperation.deleteComment), 50);
      expect(quota.state.usageFor(QuotaOperation.deleteLiveChat), 50);
      final deleted = await c.read(deletedIdsProvider.future);
      expect(deleted[QueueItemKind.comment], {'c1'});
      expect(deleted[QueueItemKind.liveChat], {'l1'});
      expect(c.read(deletionProcessingProvider), DeletionProcessingState.idle);
    });

    test('a failed item keeps its error and the rest are still sent', () async {
      final c = await start(
        [_item('a1'), _item('a2')],
        answers: {'a1': _Answer.failed},
      );

      await process(c);

      expect(youtube.sent, ['a1', 'a2']);
      final items = await queue(c);
      expect(items['a1']!.status, DeletionItemStatus.failed);
      expect(items['a1']!.errorMessage, 'comment not found');
      expect(items['a1']!.processedAt, isNotNull);
      expect(items['a2']!.status, DeletionItemStatus.succeeded);
      expect((await c.read(deletedIdsProvider.future))[QueueItemKind.comment], {
        'a2',
      });
      expect(quota.state.usageFor(QuotaOperation.deleteComment), 50);
      expect(c.read(deletionProcessingProvider), DeletionProcessingState.idle);
    });

    test("running out of quota stops, leaving the channel's other items for "
        'the next day', () async {
      final c = await start(
        [
          _item('a1'),
          _item('a2'),
          _item('b1', channel: 'UCb'),
          _item('af', status: DeletionItemStatus.failed),
        ],
        answers: {'a1': _Answer.quotaExceeded},
      );

      await process(c);

      expect(youtube.sent, ['a1']);
      final items = await queue(c);
      expect(items['a1']!.status, DeletionItemStatus.quotaExceeded);
      expect(items['a1']!.errorMessage, 'quota gone');
      expect(items['a1']!.processedAt, isNotNull);
      expect(items['a2']!.status, DeletionItemStatus.quotaExceeded);
      expect(items['b1']!.status, DeletionItemStatus.pending);
      expect(items['af']!.status, DeletionItemStatus.failed);
      expect(quota.state.usageFor(QuotaOperation.deleteComment), 0);
      expect(c.read(deletionProcessingProvider), DeletionProcessingState.idle);
    });

    test(
      'a sign-in that stops working stops, keeping items to delete',
      () async {
        final c = await start(
          [_item('a1'), _item('a2')],
          answers: {'a1': _Answer.signInFailed},
        );

        await process(c);

        expect(youtube.sent, ['a1']);
        expect(signIns.failed, ['UCa']);
        final items = await queue(c);
        expect(items['a1'], _item('a1'));
        expect(items['a2'], _item('a2'));
        expect(await c.read(deletedIdsProvider.future), {
          QueueItemKind.comment: <String>{},
          QueueItemKind.liveChat: <String>{},
        });
        expect(
          c.read(deletionProcessingProvider),
          DeletionProcessingState.idle,
        );
      },
    );
  });

  group('quota', () {
    test('stops once the quota left runs out', () async {
      final c = await start([_item('a1'), _item('a2')], deletesLeft: 1);

      await process(c);

      expect(youtube.sent, ['a1']);
      expect(await statuses(c), {
        'a1': DeletionItemStatus.succeeded,
        'a2': DeletionItemStatus.quotaExceeded,
      });
    });

    test('sends nothing without quota left', () async {
      final c = await start([
        _item('a1'),
        _item('b1', channel: 'UCb'),
      ], deletesLeft: 0);

      await process(c);

      expect(youtube.sent, isEmpty);
      expect(await statuses(c), {
        'a1': DeletionItemStatus.quotaExceeded,
        'b1': DeletionItemStatus.pending,
      });
    });

    test('items the quota stopped are tried again', () async {
      final c = await start([
        _item('aq', status: DeletionItemStatus.quotaExceeded),
        _item('bq', channel: 'UCb', status: DeletionItemStatus.quotaExceeded),
      ]);

      await process(c);

      expect(youtube.sent, ['aq']);
      expect(await statuses(c), {
        'aq': DeletionItemStatus.succeeded,
        'bq': DeletionItemStatus.quotaExceeded,
      });
    });
  });

  group('state', () {
    test('runs until paused, finishing the item being deleted', () async {
      final c = await start([_item('a1'), _item('a2')]);
      youtube.gate = Completer();
      final processing = c.read(deletionProcessingProvider.notifier);

      final done = process(c);
      await pumpEventQueue();
      expect(youtube.sent, ['a1']);
      expect(
        c.read(deletionProcessingProvider),
        DeletionProcessingState.running,
      );
      expect((await queue(c))['a1']!.status, DeletionItemStatus.inProgress);

      processing.pauseProcessing();
      expect(
        c.read(deletionProcessingProvider),
        DeletionProcessingState.pausing,
      );

      youtube.gate!.complete();
      await done;

      expect(youtube.sent, ['a1']);
      expect(await statuses(c), {
        'a1': DeletionItemStatus.succeeded,
        'a2': DeletionItemStatus.pending,
      });
      expect(c.read(deletionProcessingProvider), DeletionProcessingState.idle);

      // Starting again picks up where it left off.
      youtube.gate = null;
      await process(c);
      expect(youtube.sent, ['a1', 'a2']);
      expect(c.read(deletionProcessingProvider), DeletionProcessingState.idle);
    });

    test('starting again while running does nothing', () async {
      final c = await start([_item('a1')]);
      youtube.gate = Completer();

      final first = process(c);
      await pumpEventQueue();
      await c
          .read(deletionProcessingProvider.notifier)
          .startYoutubeApiProcessing(channelId: 'UCa');
      youtube.gate!.complete();
      await first;

      expect(youtube.sent, ['a1']);
    });

    test('pausing while idle does nothing', () async {
      final c = await start([]);

      c.read(deletionProcessingProvider.notifier).pauseProcessing();

      expect(c.read(deletionProcessingProvider), DeletionProcessingState.idle);
    });
  });

  group('channels', () {
    test("never sends another channel's items", () async {
      final c = await start([
        _item('b1', channel: 'UCb'),
        _item('a1'),
        _item('unknown', channel: null),
        _item('a2'),
      ]);

      await process(c);

      expect(youtube.sent, ['a1', 'a2']);
      final items = await statuses(c);
      expect(items['b1'], DeletionItemStatus.pending);
      expect(items['unknown'], DeletionItemStatus.pending);
    });

    test(
      'deletes nothing unless signed in with the channel asked for',
      () async {
        final c = await start([_item('b1', channel: 'UCb')]);

        await process(c, channelId: 'UCb');

        expect(youtube.sent, isEmpty);
        expect(
          c.read(deletionProcessingProvider),
          DeletionProcessingState.idle,
        );
      },
    );
  });
}
