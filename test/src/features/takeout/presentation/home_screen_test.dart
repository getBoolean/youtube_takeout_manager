import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/own_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';

final _pickedZip = FilePickerResult([
  PlatformFile(
    name: 'takeout-20260501T000000Z-1-001.zip',
    size: 1,
    bytes: Uint8List(1),
  ),
]);

final _savedData = TakeoutData(
  comments: [
    Comment(
      commentId: 'A',
      channelId: 'UCme',
      createdAt: DateTime.utc(2026),
      price: 0,
      rawCommentText: '{"text":"hi"}',
      displayText: 'hi',
    ),
  ],
  liveChats: const [],
  subscriptionsByChannelId: const {},
);

TakeoutImportPlan _plan({
  String accountId = 'UCme',
  int newComments = 0,
  int newlyDeletedComments = 0,
  ChannelMismatch? differentAccount,
  List<TakeoutChannel> channels = const [],
}) => TakeoutImportPlan(
  accountId: accountId,
  mergedData: _savedData,
  channels: channels,
  csvFiles: const {},
  goneCommentIds: const {},
  goneLiveChatIds: const {},
  newlyDeletedCommentCount: newlyDeletedComments,
  newlyDeletedLiveChatCount: 0,
  newCommentCount: newComments,
  newLiveChatCount: 0,
  differentAccount: differentAccount,
);

class _FakeZipPicker implements ZipPickerRepository {
  final FilePickerResult? result;

  _FakeZipPicker(this.result);

  @override
  Future<FilePickerResult?> pickZips() async => result;
}

/// Loads [saved] (or fails with [loadError]) and answers imports with [plan]
/// (or throws [importError]), recording what the screen asks of it.
class _FakeTakeout extends TakeoutNotifier {
  final TakeoutData? saved;
  final Object? loadError;
  final TakeoutImportPlan? plan;
  final Object? importError;
  final Set<String> accountsWithData;

  final prepared = <bool>[];
  final committed = <TakeoutImportPlan>[];

  _FakeTakeout({
    this.saved,
    this.loadError,
    this.plan,
    this.importError,
    this.accountsWithData = const {},
  });

  @override
  Future<LoadedTakeout?> build() async {
    if (loadError case final error?) throw error;
    final data = saved;
    return data == null ? null : LoadedTakeout(id: 'UCme', data: data);
  }

  @override
  Future<TakeoutImportPlan> prepareImport(
    FilePickerResult picked, {
    required bool merge,
  }) async {
    prepared.add(merge);
    if (importError case final error?) throw error;
    return plan!;
  }

  @override
  Future<void> commitImport(TakeoutImportPlan plan) async {
    committed.add(plan);
    state = AsyncData(LoadedTakeout(id: 'UCme', data: plan.mergedData));
  }

  @override
  Future<bool> hasSavedData(String accountId) async =>
      accountsWithData.contains(accountId);
}

/// Keeps the fake takeout's ID selected.
class _Selection extends TakeoutSelectionNotifier {
  final channels = <String>[];

  @override
  Future<TakeoutSelection?> build() async =>
      const TakeoutSelection(takeoutId: 'UCme');

  @override
  Future<void> selectChannel(String channelId) async {
    channels.add(channelId);
    state = AsyncData(
      TakeoutSelection(takeoutId: 'UCme', channelId: channelId),
    );
  }
}

class _FakeQueue extends DeletionQueue {
  final List<DeletionQueueItem> items;

  _FakeQueue([this.items = const []]);

  @override
  Future<List<DeletionQueueItem>> build() async => items;
}

/// Home with a stand-in channel list, so tests can see it opened.
class _TestRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(
      page: PageInfo(
        ChannelListRoute.name,
        builder: (_) => const Scaffold(body: Text('Channel list')),
      ),
      path: '/channels',
    ),
  ];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late _Selection selection;

  Future<void> pumpHome(
    WidgetTester tester,
    _FakeTakeout takeout, {
    FilePickerResult? picked,
    List<DeletionQueueItem> queued = const [],
  }) async {
    selection = _Selection();
    await tester.pumpWidget(
      ProviderScope(
        // Show a failed load right away instead of retrying it.
        retry: (_, _) => null,
        overrides: [
          takeoutProvider.overrideWith(() => takeout),
          takeoutSelectionProvider.overrideWith(() => selection),
          zipPickerRepositoryProvider.overrideWithValue(
            _FakeZipPicker(picked ?? _pickedZip),
          ),
          channelsProvider.overrideWithValue(const []),
          deletionQueueProvider.overrideWith(() => _FakeQueue(queued)),
        ],
        child: MaterialApp.router(routerConfig: _TestRouter().config()),
      ),
    );
    // The router builds Home a frame after it starts.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Taps [button] and lets the import run up to its next dialog or result.
  /// The import spinner never settles, so this pumps a fixed time instead.
  Future<void> tapAndWait(WidgetTester tester, String button) async {
    await tester.ensureVisible(find.text(button));
    await tester.tap(find.text(button));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('adding a takeout confirms, saves and says what changed', (
    tester,
  ) async {
    final takeout = _FakeTakeout(
      saved: _savedData,
      plan: _plan(newComments: 1, newlyDeletedComments: 3),
    );
    await pumpHome(tester, takeout);

    await tapAndWait(tester, 'Add Newer Takeout');
    expect(find.text('Add this takeout?'), findsOneWidget);
    expect(takeout.committed, isEmpty);

    await tapAndWait(tester, 'Add');

    expect(takeout.prepared, [true]);
    expect(takeout.committed, hasLength(1));
    expect(
      find.text('Added 1 comment and 0 live chats. Marked 3 comments deleted.'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the confirmation saves nothing', (tester) async {
    final takeout = _FakeTakeout(saved: _savedData, plan: _plan());
    await pumpHome(tester, takeout);

    await tapAndWait(tester, 'Add Newer Takeout');
    await tapAndWait(tester, 'Cancel');

    expect(takeout.committed, isEmpty);
    expect(find.text('Add Newer Takeout'), findsOneWidget);
  });

  testWidgets('a takeout from another account is refused loudly', (
    tester,
  ) async {
    final takeout = _FakeTakeout(
      saved: _savedData,
      importError: const TakeoutAccountMismatchException(
        'This takeout is from a different YouTube account than your current '
        'data.',
        expectedChannelIds: {'UCme'},
        foundChannelIds: {'UCother'},
      ),
    );
    await pumpHome(tester, takeout);

    await tapAndWait(tester, 'Add Newer Takeout');

    expect(find.text('Different YouTube account'), findsOneWidget);
    expect(find.text('youtube.com/channel/UCother'), findsOneWidget);
    expect(takeout.committed, isEmpty);
  });

  testWidgets(
    "replacing warns when the takeout's channel already has saved data",
    (tester) async {
      final takeout = _FakeTakeout(
        saved: _savedData,
        plan: _plan(
          accountId: 'UCother',
          differentAccount: const ChannelMismatch(
            expectedChannelIds: {'UCme'},
            foundChannelIds: {'UCother'},
          ),
        ),
        accountsWithData: {'UCother'},
      );
      await pumpHome(tester, takeout);

      await tapAndWait(tester, 'Replace Data');

      expect(takeout.prepared, [false]);
      expect(
        find.textContaining('replaces the data already saved for UCother'),
        findsOneWidget,
      );
    },
  );

  testWidgets('replacing saved data that failed to load asks first', (
    tester,
  ) async {
    final takeout = _FakeTakeout(
      loadError: Exception('file locked'),
      plan: _plan(),
    );
    await pumpHome(tester, takeout);

    await tapAndWait(tester, 'Import New Data');

    expect(find.textContaining("couldn't be loaded"), findsOneWidget);
    expect(takeout.committed, isEmpty);
  });

  testWidgets('a first import with nothing to review saves without asking', (
    tester,
  ) async {
    final takeout = _FakeTakeout(plan: _plan());
    await pumpHome(tester, takeout);

    await tapAndWait(tester, 'Select Zip Files');

    expect(find.byType(AlertDialog), findsNothing);
    expect(takeout.committed, hasLength(1));
    // Opens the channels even when signed out.
    expect(find.text('Channel list'), findsOneWidget);
  });

  testWidgets('offers the channels when signed out', (tester) async {
    await pumpHome(tester, _FakeTakeout(saved: _savedData));

    expect(find.text('Sign in to View Channels'), findsNothing);
    expect(
      find.text('Signed out: video titles and YouTube API deletion are off.'),
      findsOneWidget,
    );

    await tester.tap(find.text('View Channels'));
    await tester.pumpAndSettle();
    expect(find.text('Channel list'), findsOneWidget);
  });

  testWidgets('cancelling the file picker does nothing', (tester) async {
    final takeout = _FakeTakeout(saved: _savedData, plan: _plan());
    await pumpHome(tester, takeout, picked: FilePickerResult([]));

    await tapAndWait(tester, 'Add Newer Takeout');

    expect(takeout.prepared, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the app bar has the account button', (tester) async {
    await pumpHome(tester, _FakeTakeout(saved: _savedData));

    expect(find.byTooltip('Account'), findsOneWidget);
  });

  testWidgets('says nothing about an empty deletion queue', (tester) async {
    await pumpHome(tester, _FakeTakeout(saved: _savedData));
    await tester.pump();

    expect(find.textContaining('waiting to be deleted'), findsNothing);
  });

  testWidgets('says what is waiting in the deletion queue', (tester) async {
    await pumpHome(
      tester,
      _FakeTakeout(saved: _savedData),
      queued: [
        for (final (i, status) in [
          DeletionItemStatus.pending,
          DeletionItemStatus.quotaExceeded,
          DeletionItemStatus.failed,
          DeletionItemStatus.succeeded,
        ].indexed)
          DeletionQueueItem(
            id: '$i',
            itemId: 'c$i',
            itemType: QueueItemKind.comment,
            status: status,
            createdAt: DateTime.utc(2026),
            authorChannelId: 'UCme',
          ),
      ],
    );
    // The queue starts loading once the summary shows it.
    await tester.pump();

    expect(
      find.text('2 items waiting to be deleted · 1 failed'),
      findsOneWidget,
    );
  });

  group('channels', () {
    final twoChannels = _savedData.copyWith(
      comments: [
        ..._savedData.comments,
        _savedData.comments.first.copyWith(commentId: 'B', channelId: 'UCalt'),
      ],
      ownChannels: const {
        'UCme': OwnChannel(channelId: 'UCme', title: 'Boolean'),
        'UCalt': OwnChannel(channelId: 'UCalt', title: 'Gaming Alt'),
      },
    );

    testWidgets('names the viewed channel, and offers to change it', (
      tester,
    ) async {
      await pumpHome(tester, _FakeTakeout(saved: twoChannels));

      expect(find.text('Boolean'), findsOneWidget);
      expect(find.text('1 of 2 channels'), findsOneWidget);

      await tester.tap(find.text('Change channel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gaming Alt'));
      await tester.pumpAndSettle();

      expect(selection.channels, ['UCalt']);
    });

    testWidgets('a takeout with one channel has nothing to change', (
      tester,
    ) async {
      await pumpHome(tester, _FakeTakeout(saved: _savedData));

      expect(find.text('Change channel'), findsNothing);
    });

    testWidgets('after replacing with a takeout of several channels, asks '
        'which to view', (tester) async {
      final takeout = _FakeTakeout(
        plan: _plan(
          accountId: 'UCnew',
          channels: const [
            TakeoutChannel(channelId: 'UCnew', isMain: true, listed: true),
            TakeoutChannel(
              channelId: 'UCnew2',
              title: 'Second',
              isMain: false,
              listed: true,
            ),
          ],
        ),
      );
      await pumpHome(tester, takeout);

      await tapAndWait(tester, 'Select Zip Files');
      expect(find.text('Choose a channel'), findsOneWidget);
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();

      expect(selection.channels, ['UCnew2']);
      expect(find.text('Channel list'), findsOneWidget);
    });
  });
}
