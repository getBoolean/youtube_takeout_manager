import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_error_dialog.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_review.dart';

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
  differentAccount: ChannelMismatch(
    expectedChannelIds: {'UCme'},
    foundChannelIds: {'UCnew'},
  ),
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('a new account names its channel without warning it differs', (
    tester,
  ) async {
    await _pump(
      tester,
      const ImportReview(plan: _plan, merge: false, newAccount: true),
    );

    expect(find.text('Channels in this takeout'), findsOneWidget);
    expect(find.text('Somebody Else'), findsOneWidget);
    expect(find.textContaining('different YouTube channel'), findsNothing);
    expect(find.textContaining('will be removed from the app'), findsNothing);
  });

  testWidgets('import errors show inline, naming the channels', (tester) async {
    await _pump(
      tester,
      const ImportErrorDetails(
        error: TakeoutAccountMismatchException(
          'This takeout has channels from more than one saved takeout.',
          expectedChannelIds: {'UCa'},
          foundChannelIds: {'UCb'},
          titlesById: {'UCa': 'Boolean'},
        ),
      ),
    );

    expect(find.textContaining('more than one saved takeout'), findsOneWidget);
    expect(find.text('Boolean'), findsOneWidget);
    expect(find.text('youtube.com/channel/UCb'), findsOneWidget);
    expect(find.text('Nothing was imported.'), findsOneWidget);
  });

  testWidgets('other errors show their message', (tester) async {
    await _pump(tester, ImportErrorDetails(error: Exception('disk full')));

    expect(find.textContaining('disk full'), findsOneWidget);
    expect(find.text('Nothing was imported.'), findsOneWidget);
  });
}
