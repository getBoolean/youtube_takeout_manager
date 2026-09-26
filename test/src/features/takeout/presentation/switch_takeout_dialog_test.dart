import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/switch_takeout_dialog.dart';

TakeoutSummary _summary(
  String id,
  String title, {
  List<TakeoutChannel> more = const [],
}) => TakeoutSummary(
  id: id,
  channels: [
    TakeoutChannel(
      channelId: id,
      title: title,
      isMain: true,
      listed: true,
      commentCount: 1234,
      liveChatCount: 56,
    ),
    ...more,
  ],
  latestExportAt: DateTime.utc(2026, 4, 12),
  countsKnown: true,
);

final _boolean = _summary(
  'UCme',
  'Boolean',
  more: const [
    TakeoutChannel(
      channelId: 'UCalt',
      title: 'Gaming Alt',
      isMain: false,
      listed: true,
    ),
  ],
);
final _work = _summary('UCwork', 'Work Channel');

class _Saved extends SavedTakeouts {
  final removed = <String>[];

  @override
  Future<List<TakeoutSummary>> build() async => [_boolean, _work];

  @override
  Future<TakeoutRemoval> planRemoval(String takeoutId) async => TakeoutRemoval(
    summary: takeoutId == 'UCwork' ? _work : _boolean,
    orphanedChannelIds: {takeoutId},
    queuedCount: 3,
    signInIds: {takeoutId},
  );

  @override
  Future<void> removeTakeout(TakeoutRemoval removal) async =>
      removed.add(removal.summary.id);
}

class _Selection extends TakeoutSelectionNotifier {
  final selected = <String>[];

  @override
  Future<TakeoutSelection?> build() async =>
      const TakeoutSelection(takeoutId: 'UCme');

  @override
  Future<void> select(String takeoutId, {String? channelId}) async {
    selected.add(takeoutId);
    state = AsyncData(TakeoutSelection(takeoutId: takeoutId));
  }
}

class _SignIns extends SavedSignIns {
  final removed = <String>[];

  @override
  Future<Map<String, SignInProfile>> build() async => const {
    'UCwork': SignInProfile(channelId: 'UCwork'),
    'UCelsewhere': SignInProfile(
      channelId: 'UCelsewhere',
      channelTitle: 'Old Channel',
    ),
  };

  @override
  Future<void> remove(String channelId, {bool revoke = false}) async {
    removed.add(channelId);
    state = AsyncData({...state.requireValue}..remove(channelId));
  }
}

class _Processing extends DeletionProcessing {
  final DeletionProcessingState initial;

  _Processing(this.initial);

  @override
  DeletionProcessingState build() => initial;
}

void main() {
  late _Saved saved;
  late _Selection selection;
  late _SignIns signIns;

  Future<void> pumpDialog(
    WidgetTester tester, {
    DeletionProcessingState processing = DeletionProcessingState.idle,
  }) async {
    saved = _Saved();
    selection = _Selection();
    signIns = _SignIns();
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedTakeoutsProvider.overrideWith(() => saved),
          takeoutSelectionProvider.overrideWith(() => selection),
          savedSignInsProvider.overrideWith(() => signIns),
          deletionProcessingProvider.overrideWith(
            () => _Processing(processing),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SwitchTakeoutDialog())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists each saved takeout, marking the one viewed', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Boolean'), findsOneWidget);
    expect(find.text('Work Channel'), findsOneWidget);
    expect(find.text('Viewing'), findsOneWidget);
    expect(
      find.textContaining('2 channels · 1,234 comments · 56 live chats'),
      findsOneWidget,
    );
  });

  testWidgets('switches to another takeout', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    expect(selection.selected, ['UCwork']);
  });

  testWidgets('says what removing a takeout removes before doing it', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();

    expect(find.text('Remove Work Channel?'), findsOneWidget);
    expect(find.textContaining('3 queued deletions'), findsOneWidget);
    expect(find.textContaining('Nothing is deleted from YouTube'), findsOne);

    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(saved.removed, ['UCwork']);
  });

  testWidgets('cancelling the removal keeps the takeout', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(saved.removed, isEmpty);
  });

  testWidgets('lists sign-ins for channels in no saved takeout', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Other saved sign-ins'), findsOneWidget);
    expect(find.text('Old Channel'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Remove sign-in'));
    await tester.pumpAndSettle();
    expect(signIns.removed, ['UCelsewhere']);
    expect(find.text('Old Channel'), findsNothing);
  });

  testWidgets("won't switch while deleting through the API", (tester) async {
    await pumpDialog(tester, processing: DeletionProcessingState.running);

    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    expect(find.text('Deleting in progress'), findsOneWidget);
    expect(selection.selected, isEmpty);
  });
}
