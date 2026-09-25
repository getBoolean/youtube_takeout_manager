import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_confirm_dialog.dart';

TakeoutImportPlan _plan({
  int newComments = 0,
  int newLiveChats = 0,
  int newlyDeletedComments = 0,
  DeletionCheckSkipReason? commentCheckSkipped,
  ChannelMismatch? differentAccount,
}) => TakeoutImportPlan(
  accountId: 'UCme',
  mergedData: const TakeoutData(
    comments: [],
    liveChats: [],
    subscriptionsByChannelId: {},
  ),
  csvFiles: const {},
  goneCommentIds: const {},
  goneLiveChatIds: const {},
  newlyDeletedCommentCount: newlyDeletedComments,
  newlyDeletedLiveChatCount: 0,
  newCommentCount: newComments,
  newLiveChatCount: newLiveChats,
  commentCheckSkipped: commentCheckSkipped,
  differentAccount: differentAccount,
);

void main() {
  /// Opens [dialog] and returns a getter for what it pops once closed.
  Future<Future<bool?> Function()> open(
    WidgetTester tester,
    ImportConfirmDialog dialog,
  ) async {
    late Future<bool?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => result = showDialog<bool>(
              context: context,
              builder: (_) => dialog,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('adding lists new items and the ones to mark deleted', (
    tester,
  ) async {
    final result = await open(
      tester,
      ImportConfirmDialog(
        plan: _plan(newComments: 1, newLiveChats: 3, newlyDeletedComments: 2),
        merge: true,
        hasSavedData: true,
      ),
    );

    expect(find.text('1 new comment'), findsOneWidget);
    expect(find.text('3 new live chats'), findsOneWidget);
    expect(find.text('2 comments will be marked deleted'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(await result(), isTrue);
  });

  testWidgets('cancelling returns false', (tester) async {
    final result = await open(
      tester,
      ImportConfirmDialog(plan: _plan(), merge: true, hasSavedData: true),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result(), isFalse);
  });

  testWidgets('replacing warns that data only saved here is removed', (
    tester,
  ) async {
    await open(
      tester,
      ImportConfirmDialog(plan: _plan(), merge: false, hasSavedData: true),
    );

    expect(find.textContaining('will be removed from the app'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
  });

  testWidgets(
    "replacing with another channel's takeout says the current data is kept",
    (tester) async {
      await open(
        tester,
        ImportConfirmDialog(
          plan: _plan(
            differentAccount: const ChannelMismatch(
              expectedChannelIds: {'UCNvbaa8lnkDE7-qc3zcePLA'},
              foundChannelIds: {'UCother'},
            ),
          ),
          merge: false,
          hasSavedData: true,
        ),
      );

      expect(find.textContaining('different YouTube channel'), findsOneWidget);
      expect(find.textContaining('UCother'), findsOneWidget);
      expect(find.textContaining('UCNvbaa8lnkDE7-qc3zcePLA'), findsOneWidget);
      expect(find.textContaining('stays saved'), findsOneWidget);
      expect(find.textContaining('will be removed from the app'), findsNothing);
      expect(find.text('Import another channel?'), findsOneWidget);
      expect(find.text('Import'), findsOneWidget);
    },
  );

  testWidgets('explains why missing comments were not marked deleted', (
    tester,
  ) async {
    await open(
      tester,
      ImportConfirmDialog(
        plan: _plan(
          commentCheckSkipped: DeletionCheckSkipReason.incompleteFiles,
        ),
        merge: true,
        hasSavedData: true,
      ),
    );

    expect(
      find.textContaining('Some comment files may be missing'),
      findsOneWidget,
    );
    expect(find.textContaining('pick every part'), findsOneWidget);
  });

  testWidgets('explains when the saved data could not be checked against', (
    tester,
  ) async {
    await open(
      tester,
      ImportConfirmDialog(
        plan: _plan(
          commentCheckSkipped: DeletionCheckSkipReason.savedDataUnverified,
        ),
        merge: true,
        hasSavedData: true,
      ),
    );

    expect(
      find.textContaining('Your saved comments are newer than this takeout'),
      findsOneWidget,
    );
  });
  testWidgets(
    "replacing with another channel's takeout says its saved data is replaced",
    (tester) async {
      await open(
        tester,
        ImportConfirmDialog(
          plan: _plan(
            differentAccount: const ChannelMismatch(
              expectedChannelIds: {'UCNvbaa8lnkDE7-qc3zcePLA'},
              foundChannelIds: {'UCother'},
            ),
          ),
          merge: false,
          hasSavedData: true,
          replacesSavedData: true,
        ),
      );

      expect(
        find.textContaining('replaces the data already saved for UCother'),
        findsOneWidget,
      );
      expect(find.textContaining('stays saved'), findsOneWidget);
    },
  );

  testWidgets('replacing data that could not be loaded warns about it', (
    tester,
  ) async {
    await open(
      tester,
      ImportConfirmDialog(
        plan: _plan(),
        merge: false,
        hasSavedData: false,
        savedDataUnreadable: true,
      ),
    );

    expect(find.textContaining("couldn't be loaded"), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
  });

  testWidgets('replacing data saved for a channel that is not shown warns '
      'that it is removed', (tester) async {
    await open(
      tester,
      ImportConfirmDialog(
        plan: _plan(),
        merge: false,
        hasSavedData: false,
        replacesSavedData: true,
      ),
    );

    expect(find.textContaining('will be removed from the app'), findsOneWidget);
  });
}
