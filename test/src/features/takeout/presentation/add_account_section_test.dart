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
  newlyDeletedCommentIds: {},
  newlyDeletedLiveChatIds: {},
  newCommentIds: {},
  newLiveChatIds: {},
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
  newlyDeletedCommentIds: {},
  newlyDeletedLiveChatIds: {},
  newCommentIds: {'c1', 'c2', 'c3'},
  newLiveChatIds: {},
);

void main() {
  late int starts, confirms, dismisses;

  Future<void> pump(
    WidgetTester tester,
    AddAccountState state, {
    bool enabled = true,
  }) {
    starts = confirms = dismisses = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddAccountSection(
              state: state,
              enabled: enabled,
              onStart: () => starts++,
              onConfirm: () => confirms++,
              onDismiss: () => dismisses++,
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
    await pump(
      tester,
      const AddAccountReview((plan: _plan, csvFiles: {}, exports: [])),
    );

    expect(find.byType(Dialog), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('add-account-review')),
        matching: find.text('Somebody Else'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.tap(find.text('Cancel'));
    expect(confirms, 1);
    expect(dismisses, 1);
  });

  testWidgets("can't merge while deleting", (tester) async {
    await pump(
      tester,
      const AddAccountMergeReview((
        plan: _mergePlan,
        csvFiles: {},
        exports: [],
      )),
      enabled: false,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    expect(confirms, 0);
  });

  testWidgets('reviews the merge before saving it', (tester) async {
    await pump(
      tester,
      const AddAccountMergeReview((
        plan: _mergePlan,
        csvFiles: {},
        exports: [],
      )),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('add-account-merge-review')),
        matching: find.textContaining('3'),
      ),
      findsOneWidget,
    );

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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('add-account-failed')),
        matching: find.byKey(const ValueKey('nothing-imported')),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Dismiss'));
    expect(dismisses, 1);
  });
}
