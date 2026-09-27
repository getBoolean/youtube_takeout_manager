import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/add_account_import.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/add_account_section.dart';

const _plan = TakeoutImportPlan(
  accountId: 'UCnew',
  channels: [
    TakeoutChannel(
      channelId: 'UCnew',
      title: 'Somebody Else',
      isMain: true,
      listed: true,
    ),
  ],
  mergedData: TakeoutData(
    comments: [],
    liveChats: [],
    subscriptionsByChannelId: {},
  ),
  goneCommentIds: {},
  goneLiveChatIds: {},
  newlyDeletedCommentCount: 0,
  newlyDeletedLiveChatCount: 0,
  newCommentCount: 0,
  newLiveChatCount: 0,
);

const _mergePlan = TakeoutImportPlan(
  accountId: 'UCme',
  mergedData: TakeoutData(
    comments: [],
    liveChats: [],
    subscriptionsByChannelId: {},
  ),
  goneCommentIds: {},
  goneLiveChatIds: {},
  newlyDeletedCommentCount: 0,
  newlyDeletedLiveChatCount: 0,
  newCommentCount: 3,
  newLiveChatCount: 0,
);

void main() {
  late int starts, confirms, dismisses;
  late int merges;

  Future<void> pump(
    WidgetTester tester,
    AddAccountState state, {
    bool enabled = true,
    String? viewedTakeoutId,
  }) {
    starts = confirms = dismisses = 0;
    merges = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddAccountSection(
              state: state,
              enabled: enabled,
              accountNames: const {'UCme': 'Boolean'},
              viewedTakeoutId: viewedTakeoutId,
              onStart: () => starts++,
              onConfirm: () => confirms++,
              onDismiss: () => dismisses++,
              onMerge: () => merges++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('offers to add another account', (tester) async {
    await pump(tester, const AddAccountIdle());

    await tester.tap(find.text('Import a takeout'));
    expect(starts, 1);
  });

  testWidgets("can't add one while deleting", (tester) async {
    await pump(tester, const AddAccountIdle(), enabled: false);

    await tester.tap(find.text('Import a takeout'));
    expect(starts, 0);
  });

  testWidgets('says it is reading the takeout', (tester) async {
    await pump(tester, const AddAccountWorking());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('reviews the takeout in place before adding it', (tester) async {
    await pump(tester, const AddAccountReview(_plan));

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Import this takeout?'), findsOneWidget);
    expect(find.text('Somebody Else'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.tap(find.text('Cancel'));
    expect(confirms, 1);
    expect(dismisses, 1);
  });

  testWidgets('warns an account is already imported, asking to merge', (
    tester,
  ) async {
    await pump(tester, const AddAccountAlreadySaved('UCme'));

    expect(find.text('Takeout already imported'), findsOneWidget);
    expect(find.textContaining("from Boolean's account"), findsOneWidget);
    expect(find.textContaining('Merging shows Boolean'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.tap(find.text('Cancel'));
    expect(merges, 1);
    expect(dismisses, 1);
  });

  testWidgets('merging into the account shown needs no switch', (tester) async {
    await pump(
      tester,
      const AddAccountAlreadySaved('UCme'),
      viewedTakeoutId: 'UCme',
    );

    expect(find.textContaining('(the one shown)'), findsOneWidget);
    expect(find.textContaining('Merging shows'), findsNothing);
  });

  testWidgets("can't merge while deleting", (tester) async {
    await pump(tester, const AddAccountAlreadySaved('UCme'), enabled: false);

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    expect(merges, 0);
  });

  testWidgets('reviews the merge before saving it', (tester) async {
    await pump(tester, const AddAccountMergeReview(_mergePlan));

    expect(find.text('Merge this takeout?'), findsOneWidget);
    expect(find.text('3 new comments'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.tap(find.text('Cancel'));
    expect(confirms, 1);
    expect(dismisses, 1);
  });

  testWidgets('says why it failed, in place', (tester) async {
    await pump(
      tester,
      const AddAccountFailed(
        TakeoutAccountMismatchException(
          'This takeout has channels from more than one saved takeout.',
          expectedChannelIds: {'UCa', 'UCb'},
          foundChannelIds: {'UCa', 'UCb'},
        ),
      ),
    );

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Different YouTube account'), findsOneWidget);
    expect(find.text('Nothing was imported.'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    expect(dismisses, 1);
  });
}
