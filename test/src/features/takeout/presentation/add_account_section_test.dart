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
  csvFiles: {},
  goneCommentIds: {},
  goneLiveChatIds: {},
  newlyDeletedCommentCount: 0,
  newlyDeletedLiveChatCount: 0,
  newCommentCount: 0,
  newLiveChatCount: 0,
);

void main() {
  late int starts, confirms, dismisses;
  late List<String> viewedSaved;

  Future<void> pump(
    WidgetTester tester,
    AddAccountState state, {
    bool enabled = true,
    String? viewedTakeoutId,
  }) {
    starts = confirms = dismisses = 0;
    viewedSaved = [];
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
              onViewSaved: viewedSaved.add,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('offers to add another account', (tester) async {
    await pump(tester, const AddAccountIdle());

    await tester.tap(find.text('Add another Google account'));
    expect(starts, 1);
  });

  testWidgets("can't add one while deleting", (tester) async {
    await pump(tester, const AddAccountIdle(), enabled: false);

    await tester.tap(find.text('Add another Google account'));
    expect(starts, 0);
  });

  testWidgets('says it is reading the takeout', (tester) async {
    await pump(tester, const AddAccountWorking());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('reviews the takeout in place before adding it', (tester) async {
    await pump(tester, const AddAccountReview(_plan));

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Add this Google account?'), findsOneWidget);
    expect(find.text('Somebody Else'), findsOneWidget);

    await tester.tap(find.text('Add account'));
    await tester.tap(find.text('Cancel'));
    expect(confirms, 1);
    expect(dismisses, 1);
  });

  testWidgets('refuses an account already saved, offering to view it', (
    tester,
  ) async {
    await pump(tester, const AddAccountAlreadySaved('UCme'));

    expect(find.text('Account already saved'), findsOneWidget);
    expect(find.textContaining('from Boolean'), findsOneWidget);
    expect(find.textContaining('Nothing was imported'), findsOneWidget);

    await tester.tap(find.text('View Boolean'));
    await tester.tap(find.byTooltip('Dismiss'));
    expect(viewedSaved, ['UCme']);
    expect(dismisses, 1);
  });

  testWidgets('the account already viewed needs no view button', (
    tester,
  ) async {
    await pump(
      tester,
      const AddAccountAlreadySaved('UCme'),
      viewedTakeoutId: 'UCme',
    );

    expect(find.text('View Boolean'), findsNothing);
    expect(find.textContaining("it's the one shown"), findsOneWidget);
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
