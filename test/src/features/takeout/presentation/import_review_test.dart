import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/history_merge.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
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
  HistoryImport history = HistoryImport.none,
  bool accountAssumed = false,
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
    history: history,
    accountAssumed: accountAssumed,
  );
}

const _newComments = ValueKey('import-new-comments');
const _newLiveChats = ValueKey('import-new-live-chats');

const _commentsMarked = ValueKey('import-marks-comments-deleted');
const _liveChatsMarked = ValueKey('import-marks-live-chats-deleted');
const _commentWarning = ValueKey('import-warning-comments');
const _liveChatWarning = ValueKey('import-warning-live-chats');
const _watches = ValueKey('import-watches');
const _searches = ValueKey('import-searches');
const _watchesRemoved = ValueKey('import-watches-removed');
const _searchesRemoved = ValueKey('import-searches-removed');
const _historyWarning = ValueKey('import-warning-history');

class _NoVideos extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value(const {});
}

Future<void> _pump(
  WidgetTester tester,
  TakeoutImportPlan plan, {
  List<ImportAccount> accounts = const [],
  ValueChanged<String>? onChooseAccount,
  String? choosingAccount,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [videoMetadataProvider.overrideWith(_NoVideos.new)],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ImportReview(
            plan: plan,
            merge: true,
            accounts: accounts,
            onChooseAccount: onChooseAccount,
            choosingAccount: choosingAccount,
          ),
        ),
      ),
    ),
  ),
);

/// The saved accounts a takeout that names none can go into: the one it's
/// planned into (see [_plan]) and another.
const _accounts = <ImportAccount>[
  (
    takeoutId: 'UCnew',
    name: 'Somebody Else',
    pictureUrl: 'https://yt3.example/new',
    details: '12 comments',
  ),
  (
    takeoutId: 'UCwork',
    name: 'Work',
    pictureUrl: 'https://yt3.example/work',
    details: '3 comments',
  ),
];

Finder _account(String takeoutId) =>
    find.byKey(ValueKey('import-account-$takeoutId'));

bool _picked(WidgetTester tester, String takeoutId) =>
    tester.widget<ListTile>(_account(takeoutId)).selected;

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

  group('history', () {
    WatchEntry watch(int i) => WatchEntry(
      time: DateTime.utc(2026, 1, i + 1),
      kind: WatchKind.video,
      url: 'https://www.youtube.com/watch?v=$i',
    );

    final history = TakeoutHistory(
      watches: [for (var i = 0; i < 12; i++) watch(i)],
      searches: [SearchEntry(time: DateTime.utc(2026), query: 'cats')],
    );

    testWidgets('a new account lists how many videos it watched and searches '
        'it made', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ImportReview(
                plan: _plan(history: HistoryImport(merged: history)),
                merge: false,
              ),
            ),
          ),
        ),
      );

      expect(_textIn(_watches, '12'), findsOneWidget);
      expect(_textIn(_searches, '1'), findsOneWidget);
    });

    testWidgets('a merge lists the new history, and what was removed from it', (
      tester,
    ) async {
      await _pump(
        tester,
        _plan(
          history: HistoryImport(
            merged: history,
            newWatchCount: 7,
            newSearchCount: 0,
            newlyRemovedWatchCount: 3,
          ),
        ),
      );

      expect(_textIn(_watches, '7'), findsOneWidget);
      expect(_textIn(_searches, '0'), findsOneWidget);
      expect(_textIn(_watchesRemoved, '3'), findsOneWidget);
      expect(find.byKey(_searchesRemoved), findsNothing);
      expect(find.byKey(_historyWarning), findsNothing);
    });

    testWidgets('a takeout without history lists none', (tester) async {
      await _pump(tester, _plan());

      expect(find.byKey(_watches), findsNothing);
      expect(find.byKey(_searches), findsNothing);
    });

    testWidgets('history alone names the takeout it goes into, without '
        'comments or live chats', (tester) async {
      await _pump(
        tester,
        _plan(
          accountAssumed: true,
          history: HistoryImport(merged: history, newWatchCount: 3),
        ),
      );

      const into = ValueKey('import-account-assumed');
      expect(find.byKey(into), findsOneWidget);
      expect(_textIn(into, 'Somebody Else'), findsOneWidget);
      expect(find.byKey(_newComments), findsNothing);
      expect(find.byKey(_newLiveChats), findsNothing);
      expect(_textIn(_watches, '3'), findsOneWidget);
    });

    group('from a takeout that names no account', () {
      TakeoutImportPlan assumed() => _plan(
        accountAssumed: true,
        history: HistoryImport(merged: history, newWatchCount: 3),
      );

      testWidgets('lists the saved accounts with their pictures, the one '
          'it goes into picked', (tester) async {
        await _pump(
          tester,
          assumed(),
          accounts: _accounts,
          onChooseAccount: (_) {},
        );

        for (final account in _accounts) {
          expect(
            find.descendant(
              of: _account(account.takeoutId),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is ChannelAvatar && w.thumbnailUrl == account.pictureUrl,
              ),
            ),
            findsOneWidget,
          );
        }
        expect(_picked(tester, 'UCnew'), isTrue);
        expect(_picked(tester, 'UCwork'), isFalse);
      });

      testWidgets('tapping another account asks for it', (tester) async {
        final chosen = <String>[];
        await _pump(
          tester,
          assumed(),
          accounts: _accounts,
          onChooseAccount: chosen.add,
        );

        await tester.tap(_account('UCnew'));
        await tester.tap(_account('UCwork'));

        expect(chosen, ['UCwork']);
      });

      testWidgets('shows the account being picked as picked, working', (
        tester,
      ) async {
        await _pump(
          tester,
          assumed(),
          accounts: _accounts,
          choosingAccount: 'UCwork',
        );

        expect(_picked(tester, 'UCwork'), isTrue);
        expect(_picked(tester, 'UCnew'), isFalse);
        expect(
          find.descendant(
            of: _account('UCwork'),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
      });

      testWidgets('with one saved account, names it with its picture, with '
          'nothing to choose', (tester) async {
        final chosen = <String>[];
        await _pump(
          tester,
          assumed(),
          accounts: _accounts.take(1).toList(),
          onChooseAccount: chosen.add,
        );

        expect(
          find.descendant(
            of: _account('UCnew'),
            matching: find.byWidgetPredicate(
              (w) => w is ChannelAvatar && w.thumbnailUrl != null,
            ),
          ),
          findsOneWidget,
        );
        await tester.tap(_account('UCnew'));
        expect(chosen, isEmpty);
      });
    });

    testWidgets("warns when history couldn't be read", (tester) async {
      await _pump(
        tester,
        _plan(
          history: HistoryImport(
            merged: history,
            unreadableFiles: 1,
            removalCheckSkipped: true,
          ),
        ),
      );

      expect(find.byKey(_historyWarning), findsOneWidget);
    });

    testWidgets('warns how many history entries were unreadable', (
      tester,
    ) async {
      await _pump(
        tester,
        _plan(
          history: HistoryImport(
            merged: history,
            skippedRows: 5,
            removalCheckSkipped: true,
          ),
        ),
      );

      expect(_textIn(_historyWarning, '5'), findsOneWidget);
    });
  });
}
