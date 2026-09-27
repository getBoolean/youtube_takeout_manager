import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_items_dialog.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_review.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

Comment _comment(String id) => Comment(
  commentId: id,
  channelId: 'UCnew',
  createdAt: DateTime.utc(2026),
  price: 0,
  rawCommentText: 'text of $id',
  displayText: 'text of $id',
);

LiveChat _liveChat(String id) => LiveChat(
  liveChatId: id,
  channelId: 'UCnew',
  createdAt: DateTime.utc(2026),
  price: 0,
  rawText: 'text of $id',
  displayText: 'text of $id',
);

/// A plan whose counted items are in its data, named e.g. `new comment 0`
/// and `gone live chat 1`, alongside an unchanged comment and live chat.
TakeoutImportPlan _plan({
  int newComments = 0,
  int newlyDeletedComments = 0,
  int newlyDeletedLiveChats = 0,
  DeletionCheckSkipReason? commentCheckSkipped,
  DeletionCheckSkipReason? liveChatCheckSkipped,
  int skippedLiveChatRows = 0,
}) {
  Set<String> ids(String prefix, int count) => {
    for (var i = 0; i < count; i++) '$prefix $i',
  };
  final newCommentIds = ids('new comment', newComments);
  final goneCommentIds = ids('gone comment', newlyDeletedComments);
  final goneLiveChatIds = ids('gone live chat', newlyDeletedLiveChats);
  return TakeoutImportPlan(
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
      comments: [
        for (final id in {...newCommentIds, ...goneCommentIds, 'kept'})
          _comment(id),
      ],
      liveChats: [
        for (final id in {...goneLiveChatIds, 'kept'}) _liveChat(id),
      ],
      subscriptionsByChannelId: const {},
      skippedLiveChatRows: skippedLiveChatRows,
    ),
    goneCommentIds: goneCommentIds,
    goneLiveChatIds: goneLiveChatIds,
    newlyDeletedCommentIds: goneCommentIds,
    newlyDeletedLiveChatIds: goneLiveChatIds,
    newCommentIds: newCommentIds,
    newLiveChatIds: const {},
    commentCheckSkipped: commentCheckSkipped,
    liveChatCheckSkipped: liveChatCheckSkipped,
  );
}

const _newComments = ValueKey('import-new-comments');
const _newLiveChats = ValueKey('import-new-live-chats');

const _commentsMarked = ValueKey('import-marks-comments-deleted');
const _liveChatsMarked = ValueKey('import-marks-live-chats-deleted');
const _commentWarning = ValueKey('import-warning-comments');
const _liveChatWarning = ValueKey('import-warning-live-chats');

class _NoVideos extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value(const {});
}

Future<void> _pump(WidgetTester tester, TakeoutImportPlan plan) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [videoMetadataProvider.overrideWith(_NoVideos.new)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImportReview(plan: plan, merge: true),
            ),
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

  testWidgets('opens a list of just the new comments', (tester) async {
    await _pump(tester, _plan(newComments: 2, newlyDeletedComments: 1));

    expect(find.textContaining('text of new comment 0'), findsNothing);

    await tester.tap(find.byKey(_newComments));
    await tester.pumpAndSettle();
    final dialog = find.byType(ImportItemsDialog);
    Finder inDialog(String text) =>
        find.descendant(of: dialog, matching: find.textContaining(text));
    expect(inDialog('text of new comment 0'), findsOneWidget);
    expect(inDialog('text of new comment 1'), findsOneWidget);
    expect(inDialog('text of gone comment'), findsNothing);
    expect(inDialog('kept'), findsNothing);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
  });

  testWidgets('opens a list of what will be marked deleted, shown deleted', (
    tester,
  ) async {
    await _pump(
      tester,
      _plan(newlyDeletedComments: 2, newlyDeletedLiveChats: 1),
    );

    await tester.tap(find.byKey(_liveChatsMarked));
    await tester.pumpAndSettle();

    final dialog = tester.widget<ImportItemsDialog>(
      find.byType(ImportItemsDialog),
    );
    expect(dialog.items.map((i) => i.id), ['gone live chat 0']);
  });

  testWidgets('a count of nothing has nothing to open', (tester) async {
    await _pump(tester, _plan());

    await tester.tap(find.byKey(_newLiveChats));
    await tester.pumpAndSettle();
    expect(find.byType(ImportItemsDialog), findsNothing);
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
