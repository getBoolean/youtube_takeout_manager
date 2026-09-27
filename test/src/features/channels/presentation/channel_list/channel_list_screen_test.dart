import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/channel_list_screen.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/no_takeout_views.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/skeleton.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/legacy_takeout_migration.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_importer.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_request.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeouts_dialog.dart';

import '../channel_detail/channel_list_fixture.dart' as fixture;

const _channel = Channel(
  channelId: fixture.channelId,
  channelTitle: 'A channel I commented on',
  commentCount: 3,
  liveChatCount: 0,
);

const _data = TakeoutData(
  comments: [],
  liveChats: [],
  subscriptionsByChannelId: {},
);

TakeoutImportPlan _plan({int newlyDeletedComments = 0}) => TakeoutImportPlan(
  accountId: 'UCme',
  mergedData: _data,
  goneCommentIds: const {},
  goneLiveChatIds: const {},
  newlyDeletedCommentCount: newlyDeletedComments,
  newlyDeletedLiveChatCount: 0,
  newCommentCount: 0,
  newLiveChatCount: 0,
);

class _Picker implements ZipPickerRepository {
  @override
  Future<List<PickedZip>?> pickZips() async => [
    (name: 'takeout-001.zip', bytes: Uint8List(1)),
  ];
}

/// Nothing saved until a takeout is imported.
class _NoTakeout extends TakeoutNotifier {
  @override
  Future<LoadedTakeout?> build() async => null;
}

/// Imports [plan], selecting and showing its takeout.
class _Takeout extends TakeoutImporter {
  final TakeoutImportPlan plan;
  final committed = <TakeoutImportPlan>[];

  _Takeout(this.plan);

  @override
  void build() {}

  @override
  Future<PreparedImport> prepareImport(
    List<PickedZip> zips, {
    required bool merge,
  }) async => (plan: plan, csvFiles: const <String, Uint8List>{});

  @override
  Future<bool> hasSavedData(String accountId) async => false;

  @override
  Future<void> commitImport(PreparedImport prepared) async {
    final plan = prepared.plan;
    committed.add(plan);
    await ref.read(takeoutSelectionProvider.notifier).select(plan.accountId);
    ref
        .read(takeoutProvider.notifier)
        .show(const LoadedTakeout(id: 'UCme', data: _data));
  }
}

class _Unreadable extends TakeoutNotifier {
  @override
  Future<LoadedTakeout?> build() async =>
      throw const FormatException('Bad saved comments');
}

/// Nothing selected until a takeout is imported.
class _Selection extends TakeoutSelectionNotifier {
  @override
  Future<TakeoutSelection?> build() async => null;

  @override
  Future<void> select(String takeoutId, {String? channelId}) async =>
      state = AsyncData(TakeoutSelection(takeoutId: takeoutId));
}

class _Saved extends SavedTakeouts {
  @override
  Future<List<TakeoutSummary>> build() async => const [];
}

class _Quota extends QuotaNotifier {
  @override
  Future<QuotaState> build() async =>
      QuotaState(usageByOperation: const {}, periodStart: DateTime(2026));
}

void main() {
  late _Takeout takeout;

  Future<void> pumpScreen(
    WidgetTester tester, {
    TakeoutImportPlan? plan,
    TakeoutNotifier Function()? notifier,
    Future<void> Function(Ref ref)? migration,
  }) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    takeout = _Takeout(plan ?? _plan());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fixture.fixtureOverrides(),
          takeoutProvider.overrideWith(notifier ?? _NoTakeout.new),
          legacyTakeoutMigrationProvider.overrideWith(
            migration ?? (ref) async {},
          ),
          takeoutImporterProvider.overrideWith(() => takeout),
          savedTakeoutsProvider.overrideWith(_Saved.new),
          takeoutSelectionProvider.overrideWith(_Selection.new),
          zipPickerRepositoryProvider.overrideWithValue(_Picker()),
          quotaProvider.overrideWith(_Quota.new),
          channelsProvider.overrideWithValue(const [_channel]),
          filteredChannelsProvider.overrideWithValue(const [_channel]),
        ],
        child: const MaterialApp(home: ChannelListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('before any takeout, asks for one under the account button', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byType(TakeoutImportPrompt), findsOneWidget);
    expect(find.byType(AccountButton), findsOneWidget);
  });

  testWidgets('a clean first takeout is saved straight away and its channels '
      'show', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Select zip files'));
    await tester.pumpAndSettle();

    expect(takeout.committed, hasLength(1));
    expect(find.byType(TakeoutImportPrompt), findsNothing);
    expect(find.text('A channel I commented on'), findsOneWidget);
  });

  testWidgets('a first takeout with something to look over is reviewed in '
      'place', (tester) async {
    await pumpScreen(tester, plan: _plan(newlyDeletedComments: 2));

    await tester.tap(find.text('Select zip files'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byKey(const ValueKey('add-account-review')), findsOneWidget);
    expect(takeout.committed, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();

    expect(takeout.committed, hasLength(1));
    expect(find.text('A channel I commented on'), findsOneWidget);
  });

  testWidgets("saved data that can't be read offers the Takeouts dialog", (
    tester,
  ) async {
    await pumpScreen(tester, notifier: _Unreadable.new);
    // Loading still, while it retries briefly.
    expect(find.byType(TakeoutLoadFailed), findsNothing);
    // However long the retries take, within reason.
    for (var i = 0; i < 50; i++) {
      if (find.byType(TakeoutLoadFailed).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(TakeoutLoadFailed), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Account'));
    await tester.pumpAndSettle();

    expect(find.byType(TakeoutsDialog), findsOneWidget);
  });

  testWidgets('shows the list loading, not an import prompt, while data saved '
      'before per-account storage moves', (tester) async {
    final moving = Completer<void>();
    await pumpScreen(tester, migration: (ref) => moving.future);

    expect(find.byType(TakeoutImportPrompt), findsNothing);
    expect(find.byType(SkeletonAvatar), findsWidgets);

    moving.complete();
    await tester.pumpAndSettle();

    expect(find.byType(TakeoutImportPrompt), findsOneWidget);
  });

  testWidgets("data saved before per-account storage that can't be moved "
      'says why', (tester) async {
    await pumpScreen(
      tester,
      migration: (ref) async => throw const LegacyTakeoutMigrationException(
        "Your saved data couldn't be matched to a YouTube channel (NUL). "
        'Import your takeout again.',
      ),
    );

    expect(find.byType(TakeoutLoadFailed), findsOneWidget);
    expect(
      find.textContaining("couldn't be matched to a YouTube channel"),
      findsOneWidget,
    );
    expect(find.byType(TakeoutImportPrompt), findsNothing);
  });

  testWidgets('after data that failed to move, an imported takeout shows', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      migration: (ref) async =>
          throw const LegacyTakeoutMigrationException('No channel.'),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import a takeout'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(takeout.committed, hasLength(1));
    expect(find.byType(TakeoutLoadFailed), findsNothing);
    expect(find.text('A channel I commented on'), findsOneWidget);
  });
}
