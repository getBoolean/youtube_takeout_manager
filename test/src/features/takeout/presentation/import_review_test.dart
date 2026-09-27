import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_review.dart';

TakeoutImportPlan _plan({
  int newlyDeletedComments = 0,
  int newlyDeletedLiveChats = 0,
  DeletionCheckSkipReason? commentCheckSkipped,
  DeletionCheckSkipReason? liveChatCheckSkipped,
  int skippedLiveChatRows = 0,
}) => TakeoutImportPlan(
  accountId: 'UCnew',
  channels: const [
    TakeoutChannel(
      channelId: 'UCnew',
      title: 'Somebody Else',
      isMain: true,
      listed: true,
    ),
  ],
  mergedData: TakeoutData(
    comments: const [],
    liveChats: const [],
    subscriptionsByChannelId: const {},
    skippedLiveChatRows: skippedLiveChatRows,
  ),
  goneCommentIds: const {},
  goneLiveChatIds: const {},
  newlyDeletedCommentCount: newlyDeletedComments,
  newlyDeletedLiveChatCount: newlyDeletedLiveChats,
  newCommentCount: 0,
  newLiveChatCount: 0,
  commentCheckSkipped: commentCheckSkipped,
  liveChatCheckSkipped: liveChatCheckSkipped,
);

const _commentsMarked = ValueKey('import-marks-comments-deleted');
const _liveChatsMarked = ValueKey('import-marks-live-chats-deleted');
const _commentWarning = ValueKey('import-warning-comments');
const _liveChatWarning = ValueKey('import-warning-live-chats');

Future<void> _pump(WidgetTester tester, TakeoutImportPlan plan) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ImportReview(plan: plan, merge: true),
          ),
        ),
      ),
    );

Finder _textIn(Key key, String text) =>
    find.descendant(of: find.byKey(key), matching: find.textContaining(text));

void main() {
  testWidgets('a new account names its channel without warnings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ImportReview(plan: _plan(), merge: false),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('import-review-channels')), findsOne);
    expect(find.text('Somebody Else'), findsOneWidget);
    for (final key in [
      _commentsMarked,
      _liveChatsMarked,
      _commentWarning,
      _liveChatWarning,
    ]) {
      expect(find.byKey(key), findsNothing);
    }
  });

  testWidgets('says how many comments and live chats will be marked deleted', (
    tester,
  ) async {
    await _pump(
      tester,
      _plan(newlyDeletedComments: 12, newlyDeletedLiveChats: 3),
    );

    expect(_textIn(_commentsMarked, '12'), findsOneWidget);
    expect(_textIn(_liveChatsMarked, '3'), findsOneWidget);
  });

  testWidgets('leaves out a kind with nothing to mark deleted', (tester) async {
    await _pump(tester, _plan(newlyDeletedLiveChats: 2));

    expect(find.byKey(_commentsMarked), findsNothing);
    expect(_textIn(_liveChatsMarked, '2'), findsOneWidget);
  });

  testWidgets('warns when the comment deletion check was skipped', (
    tester,
  ) async {
    await _pump(
      tester,
      _plan(commentCheckSkipped: DeletionCheckSkipReason.incompleteFiles),
    );

    expect(find.byKey(_commentWarning), findsOneWidget);
    expect(find.byKey(_liveChatWarning), findsNothing);
  });

  testWidgets('warns when the live chat deletion check was skipped, saying '
      'how many rows were unreadable', (tester) async {
    await _pump(
      tester,
      _plan(
        liveChatCheckSkipped: DeletionCheckSkipReason.unparsedRows,
        skippedLiveChatRows: 4,
      ),
    );

    expect(find.byKey(_commentWarning), findsNothing);
    expect(_textIn(_liveChatWarning, '4'), findsOneWidget);
  });

  testWidgets('warns about saved data that may be incomplete', (tester) async {
    await _pump(
      tester,
      _plan(
        commentCheckSkipped: DeletionCheckSkipReason.savedDataUnverified,
        liveChatCheckSkipped: DeletionCheckSkipReason.savedDataUnverified,
      ),
    );

    expect(find.byKey(_commentWarning), findsOneWidget);
    expect(find.byKey(_liveChatWarning), findsOneWidget);
  });
}
