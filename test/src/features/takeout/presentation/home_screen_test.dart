import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/home_screen.dart';

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
}) => TakeoutImportPlan(
  accountId: accountId,
  mergedData: _savedData,
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
  Future<TakeoutData?> build() async {
    if (loadError case final error?) throw error;
    return saved;
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
    state = AsyncData(plan.mergedData);
  }

  @override
  Future<bool> hasSavedData(String accountId) async =>
      accountsWithData.contains(accountId);
}

class _EmptyQueue extends DeletionQueue {
  @override
  Future<List<DeletionQueueItem>> build() async => [];
}

void main() {
  Future<void> pumpHome(
    WidgetTester tester,
    _FakeTakeout takeout, {
    FilePickerResult? picked,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        // Show a failed load right away instead of retrying it.
        retry: (_, _) => null,
        overrides: [
          takeoutProvider.overrideWith(() => takeout),
          zipPickerRepositoryProvider.overrideWithValue(
            _FakeZipPicker(picked ?? _pickedZip),
          ),
          channelsProvider.overrideWithValue(const []),
          deletionQueueProvider.overrideWith(_EmptyQueue.new),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Taps [button] and lets the import run up to its next dialog or result.
  /// The import spinner never settles, so this pumps a fixed time instead.
  Future<void> tapAndWait(WidgetTester tester, String button) async {
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
    expect(
      find.text('Sign in to fetch video metadata and view channels.'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the file picker does nothing', (tester) async {
    final takeout = _FakeTakeout(saved: _savedData, plan: _plan());
    await pumpHome(tester, takeout, picked: FilePickerResult([]));

    await tapAndWait(tester, 'Add Newer Takeout');

    expect(takeout.prepared, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
