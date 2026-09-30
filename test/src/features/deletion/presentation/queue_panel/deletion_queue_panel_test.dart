import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/option_card.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/google_cloud_client_setup.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/oauth_configured.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/oauth_client_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/oauth_client.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_cloud_client_form.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_cloud_setup_pages.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_filter.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_items_by_channel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/script_deletion_ids.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_method_picker.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/possible_membership_events_notice.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_filter_chips.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_panel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/empty_deletion_queue.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/unassigned_queue_notice.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/quota/presentation/quota_status_bar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeouts_dialog.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';

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

/// Deletes used today, so the deletes left aren't simply the daily limit's.
const _deletesUsed = 3;

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

  @override
  Future<void> processPendingViaYoutubeApi({required String channelId}) async =>
      calls.add('deleteViaApi $channelId');
}

class _FakeAuth extends AuthNotifier {
  final SignInProfile? initial;

  _FakeAuth(this.initial);

  @override
  SignInProfile? build() => initial;
}

class _FakeQuota extends QuotaNotifier {
  @override
  Future<QuotaState> build() async => QuotaState(
    usageByOperation: const {
      QuotaOperation.deleteComment: _deletesUsed * QuotaOperation.deleteCost,
    },
    periodStart: DateTime.utc(2026),
  );
}

class _ClientSetup extends GoogleCloudClientSetup {
  final saved = <OAuthClient>[];

  @override
  Future<void> save(OAuthClient client) async => saved.add(client);
}

/// The panel on a page of its own, and a stand-in for the script screen it
/// opens.
class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PageInfo(
        'PanelRoute',
        builder: (_) =>
            const Scaffold(body: DeletionQueuePanel(currentChannelId: 'UCb')),
      ),
      initial: true,
    ),
    AutoRoute(
      page: PageInfo(
        ScriptDeletionRoute.name,
        builder: (_) => const SizedBox(key: ValueKey('script-screen')),
      ),
    ),
  ];
}

void main() {
  late _FakeQueue queue;
  late _Router router;
  late _ClientSetup clientSetup;

  Future<void> pumpPanel(
    WidgetTester tester, {
    List<DeletionQueueItem>? items,
    bool signedIn = false,
    bool oauthConfigured = true,
    DeletionProcessingState processing = DeletionProcessingState.idle,
    List<LiveChat> liveChats = const [],
  }) async {
    queue = _FakeQueue(items ?? _items);
    router = _Router();
    clientSetup = _ClientSetup();
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
          oauthConfiguredProvider.overrideWithValue(oauthConfigured),
          oauthClientProvider.overrideWith((ref) async => null),
          googleCloudClientSetupProvider.overrideWith(() => clientSetup),
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
        child: MaterialApp.router(routerConfig: router.config()),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  Finder filterChip(DeletionQueueFilter filter) =>
      find.byKey(ValueKey('filter:${filter.name}'));

  /// What the deletes left today should read, going by the quota used.
  const deletesLeft =
      (dailyQuotaLimit - _deletesUsed * QuotaOperation.deleteCost) ~/
      QuotaOperation.deleteCost;

  Future<void> openDeleteDialog(WidgetTester tester) async {
    await tester.tap(find.text('Delete 2…'));
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

    await tester.tap(filterChip(DeletionQueueFilter.failed));
    await tester.pumpAndSettle();

    expect(find.text('text b1'), findsOneWidget);
    expect(find.text('text a1'), findsNothing);
    expect(find.text('Alpha'), findsNothing);

    // Quota-stopped items wait for the next Delete.
    await tester.tap(filterChip(DeletionQueueFilter.waiting));
    await tester.pumpAndSettle();

    expect(find.text('text a1'), findsOneWidget);
    expect(find.text('text a2'), findsOneWidget);
    expect(find.text('text b1'), findsNothing);
  });

  testWidgets('Delete asks how, for the waiting items', (tester) async {
    await pumpPanel(tester);

    await openDeleteDialog(tester);

    expect(
      find.descendant(
        of: find.byType(DeletionMethodDialog),
        matching: find.textContaining('2'),
      ),
      findsOneWidget,
    );
    expect(find.text('Via My Activity'), findsOneWidget);
    expect(find.text('Via YouTube API'), findsOneWidget);
  });

  testWidgets('signed out, choosing the API opens sign-in, and closing it '
      'returns to deleting', (tester) async {
    await pumpPanel(tester);

    await openDeleteDialog(tester);
    await tester.tap(find.text('Via YouTube API'));
    await tester.pumpAndSettle();

    expect(find.byType(TakeoutsDialog), findsOneWidget);
    expect(find.widgetWithText(OptionCard, 'Via YouTube API'), findsNothing);
    expect(queue.calls, isNot(contains(startsWith('deleteViaApi'))));

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(find.byType(TakeoutsDialog), findsNothing);
    expect(find.widgetWithText(OptionCard, 'Via YouTube API'), findsOne);
  });

  Future<void> chooseApiWithoutClient(WidgetTester tester) async {
    await pumpPanel(tester, oauthConfigured: false);
    await openDeleteDialog(tester);
    await tester.tap(find.text('Via YouTube API'));
    await tester.pumpAndSettle();
  }

  testWidgets('without a Google Cloud client, choosing the API sets one up '
      'in the same dialog, and Back returns to deleting', (tester) async {
    await chooseApiWithoutClient(tester);

    expect(find.byType(DeletionMethodDialog), findsNothing);
    expect(find.byKey(GoogleCloudSetupPages.nextKey), findsOneWidget);
    expect(queue.calls, isNot(contains(startsWith('deleteViaApi'))));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(DeletionMethodDialog), findsOneWidget);
  });

  testWidgets('saving the client set up while deleting returns to deleting', (
    tester,
  ) async {
    await chooseApiWithoutClient(tester);
    while (find.byKey(GoogleCloudSetupPages.nextKey).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(GoogleCloudSetupPages.nextKey));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
      find.descendant(
        of: find.byKey(GoogleCloudClientForm.idFieldKey),
        matching: find.byType(TextField),
      ),
      '123-abc.apps.googleusercontent.com',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(GoogleCloudClientForm.secretFieldKey),
        matching: find.byType(TextField),
      ),
      'GOCSPX-abc',
    );
    await tester.tap(find.byKey(GoogleCloudClientForm.saveKey));
    await tester.pumpAndSettle();

    expect(clientSetup.saved, [
      const OAuthClient(
        id: '123-abc.apps.googleusercontent.com',
        secret: 'GOCSPX-abc',
      ),
    ]);
    expect(find.byType(DeletionMethodDialog), findsOneWidget);
  });

  testWidgets('Delete warns about live chats with no text in the takeout', (
    tester,
  ) async {
    DeletionQueueItem chat(String id) => _item(
      id,
      DeletionItemStatus.pending,
    ).copyWith(itemType: QueueItemKind.liveChat, displayTextSnippet: null);
    LiveChat takeoutChat(String id, String text) => LiveChat(
      liveChatId: id,
      channelId: 'UCme',
      createdAt: DateTime.utc(2026),
      price: 0,
      rawText: text,
      displayText: text,
    );
    await pumpPanel(
      tester,
      items: [chat('blank'), chat('said')],
      liveChats: [takeoutChat('blank', ''), takeoutChat('said', 'hi')],
    );

    await openDeleteDialog(tester);

    final notice = find.byType(PossibleMembershipEventsNotice);
    expect(tester.widget<PossibleMembershipEventsNotice>(notice).count, 1);
  });

  testWidgets('offers the API with the deletes left when signed in', (
    tester,
  ) async {
    await pumpPanel(tester, signedIn: true);

    await openDeleteDialog(tester);

    expect(
      find.descendant(
        of: find.widgetWithText(OptionCard, 'Via YouTube API'),
        matching: find.textContaining('~$deletesLeft '),
      ),
      findsOneWidget,
    );
  });

  testWidgets("deleting via the API deletes the viewed channel's items", (
    tester,
  ) async {
    await pumpPanel(tester, signedIn: true);

    await openDeleteDialog(tester);
    await tester.tap(find.text('Via YouTube API'));
    await tester.pumpAndSettle();

    expect(find.byType(DeletionMethodDialog), findsNothing);
    expect(queue.calls, contains('deleteViaApi UCme'));
  });

  testWidgets('deleting via My Activity opens the script with the waiting '
      'items', (tester) async {
    await pumpPanel(tester);

    await openDeleteDialog(tester);
    await tester.tap(find.text('Via My Activity'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('script-screen')), findsOneWidget);
    // a1 is waiting and a2 was stopped by the quota; the rest aren't.
    expect(containerOf(tester).read(scriptDeletionIdsProvider).allIds, {
      'a1',
      'a2',
    });
    expect(queue.calls, isNot(contains('deleteViaApi UCme')));
  });

  testWidgets('closing the Delete dialog starts nothing', (tester) async {
    await pumpPanel(tester, signedIn: true);

    await openDeleteDialog(tester);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(find.byType(DeletionMethodDialog), findsNothing);
    expect(queue.calls, isEmpty);
    expect(containerOf(tester).read(scriptDeletionIdsProvider).isEmpty, isTrue);
  });

  testWidgets('shows API quota, and that My Activity has none, signed in', (
    tester,
  ) async {
    await pumpPanel(tester, signedIn: true);

    final bar = find.byType(QuotaStatusBar);
    expect(bar, findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.textContaining('~$deletesLeft ')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.textContaining('My Activity')),
      findsOneWidget,
    );
  });

  testWidgets('hides the quota when signed out', (tester) async {
    await pumpPanel(tester);

    expect(find.byType(QuotaStatusBar), findsNothing);
  });

  testWidgets('offers Pause instead of Delete while deleting', (tester) async {
    await pumpPanel(tester, processing: DeletionProcessingState.running);

    expect(find.text('Delete 2…'), findsNothing);
    await tester.tap(find.text('Pause'));
    expect(queue.calls, contains('pause'));
  });

  testWidgets('retries failed items and clears done ones', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Retry failed'));
    await tester.tap(find.text('Clear done'));

    expect(
      queue.calls,
      containsAll(['retryFailed UCme', 'clearCompleted UCme']),
    );
  });

  testWidgets('explains how to add items when empty', (tester) async {
    await pumpPanel(tester, items: const []);

    expect(find.byType(EmptyDeletionQueue), findsOneWidget);
    expect(find.byType(DeletionQueueFilterChips), findsNothing);
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

    final notice = find.byType(UnassignedQueueNotice);
    expect(tester.widget<UnassignedQueueNotice>(notice).count, 1);
    // Not in the list or its counts.
    expect(find.text('text old'), findsNothing);

    await tester.tap(find.text('Remove it'));
    expect(queue.calls, contains('removeUnassigned'));
  });
}
