import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/option_card.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_items_by_channel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_panel.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

DeletionQueueItem _item(String itemId, DeletionItemStatus status) =>
    DeletionQueueItem(
      id: 'q-$itemId',
      itemId: itemId,
      itemType: QueueItemKind.comment,
      status: status,
      displayTextSnippet: 'text $itemId',
      createdAt: DateTime.utc(2026),
      authorChannelId: 'UCme',
    );

final _items = [
  _item('a1', DeletionItemStatus.pending),
  _item('b1', DeletionItemStatus.failed),
  _item('b2', DeletionItemStatus.succeeded),
  _item('a2', DeletionItemStatus.quotaExceeded),
];

class _FakeQueue extends DeletionQueue {
  final List<DeletionQueueItem> items;
  final calls = <String>[];

  _FakeQueue(this.items);

  @override
  Future<List<DeletionQueueItem>> build() async => items;

  @override
  Future<void> retryFailed({required String channelId}) async =>
      calls.add('retryFailed $channelId');

  @override
  Future<void> clearCompleted({required String channelId}) async =>
      calls.add('clearCompleted $channelId');

  @override
  Future<void> removeUnassigned() async => calls.add('removeUnassigned');
}

class _Processing extends DeletionProcessing {
  final DeletionProcessingState initial;
  final List<String> calls;

  _Processing(this.initial, this.calls);

  @override
  DeletionProcessingState build() => initial;

  @override
  void pauseProcessing() => calls.add('pause');
}

class _FakeAuth extends AuthNotifier {
  final SignInProfile? initial;

  _FakeAuth(this.initial);

  @override
  SignInProfile? build() => initial;
}

class _FakeQuota extends QuotaNotifier {
  @override
  Future<QuotaState> build() async =>
      QuotaState(usageByOperation: const {}, periodStart: DateTime.utc(2026));
}

void main() {
  late _FakeQueue queue;

  Future<void> pumpPanel(
    WidgetTester tester, {
    List<DeletionQueueItem>? items,
    bool signedIn = false,
    DeletionProcessingState processing = DeletionProcessingState.idle,
  }) async {
    queue = _FakeQueue(items ?? _items);
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deletionQueueProvider.overrideWith(() => queue),
          viewedChannelIdProvider.overrideWithValue('UCme'),
          deletionProcessingProvider.overrideWith(
            () => _Processing(processing, queue.calls),
          ),
          queuedItemChannelIdsProvider.overrideWithValue(const {
            'a1': 'UCa',
            'a2': 'UCa',
            'b1': 'UCb',
            'b2': 'UCb',
          }),
          channelsProvider.overrideWithValue(const [
            Channel(
              channelId: 'UCa',
              channelTitle: 'Alpha',
              commentCount: 2,
              liveChatCount: 0,
            ),
            Channel(
              channelId: 'UCb',
              channelTitle: 'Bravo',
              commentCount: 2,
              liveChatCount: 0,
            ),
          ]),
          authProvider.overrideWith(
            () => _FakeAuth(
              signedIn ? const SignInProfile(channelId: 'UCme') : null,
            ),
          ),
          quotaProvider.overrideWith(_FakeQuota.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DeletionQueuePanel(currentChannelId: 'UCb')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('groups items by channel, current channel first', (tester) async {
    await pumpPanel(tester);

    final bravo = tester.getTopLeft(find.text('Bravo')).dy;
    final alpha = tester.getTopLeft(find.text('Alpha')).dy;
    expect(bravo, lessThan(alpha));
    expect(tester.getTopLeft(find.text('text a1')).dy, greaterThan(alpha));
  });

  testWidgets('filters by status', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Failed '));
    await tester.pumpAndSettle();

    expect(find.text('text b1'), findsOneWidget);
    expect(find.text('text a1'), findsNothing);
    expect(find.text('Alpha'), findsNothing);

    // Quota-stopped items wait for the next Delete.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Waiting '));
    await tester.pumpAndSettle();

    expect(find.text('text a1'), findsOneWidget);
    expect(find.text('text a2'), findsOneWidget);
    expect(find.text('text b1'), findsNothing);
  });

  testWidgets('Delete asks how, with the API needing sign-in', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Delete 2…'));
    await tester.pumpAndSettle();

    expect(find.text('Delete 2 items from YouTube'), findsOneWidget);
    expect(find.text('Via My Activity'), findsOneWidget);
    expect(find.text('Sign in required'), findsOneWidget);
    final api = tester.widget<OptionCard>(
      find.widgetWithText(OptionCard, 'Via YouTube API'),
    );
    expect(api.onTap, isNull);
  });

  testWidgets('offers the API with the deletes left when signed in', (
    tester,
  ) async {
    await pumpPanel(tester, signedIn: true);

    await tester.tap(find.text('Delete 2…'));
    await tester.pumpAndSettle();

    expect(
      find.text('Uses API quota · ~200 deletes left today'),
      findsOneWidget,
    );
  });

  testWidgets('shows API quota, and that My Activity has none, signed in', (
    tester,
  ) async {
    await pumpPanel(tester, signedIn: true);

    expect(find.text('YouTube API · ~200 deletes left today'), findsOneWidget);
    expect(find.textContaining('My Activity has no limit'), findsOneWidget);
  });

  testWidgets('hides the quota when signed out', (tester) async {
    await pumpPanel(tester);

    expect(find.textContaining('deletes left today'), findsNothing);
  });

  testWidgets('offers Pause instead of Delete while deleting', (tester) async {
    await pumpPanel(tester, processing: DeletionProcessingState.running);

    expect(find.text('Delete 2…'), findsNothing);
    await tester.tap(find.text('Pause'));
    expect(queue.calls, ['pause']);
  });

  testWidgets('retries failed items and clears done ones', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Retry failed'));
    await tester.tap(find.text('Clear done'));

    expect(queue.calls, ['retryFailed UCme', 'clearCompleted UCme']);
  });

  testWidgets('explains how to add items when empty', (tester) async {
    await pumpPanel(tester, items: const []);

    expect(find.text('Nothing queued'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('sets apart items no takeout has matched to a channel', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      items: [
        ..._items,
        _item(
          'old',
          DeletionItemStatus.pending,
        ).copyWith(authorChannelId: null),
      ],
    );

    expect(
      find.textContaining('1 item queued before channels were tracked'),
      findsOneWidget,
    );
    // Not in the list or its counts.
    expect(find.text('text old'), findsNothing);

    await tester.tap(find.text('Remove it'));
    expect(queue.calls, ['removeUnassigned']);
  });
}
