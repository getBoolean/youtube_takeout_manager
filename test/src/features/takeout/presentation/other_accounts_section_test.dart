import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/other_accounts_section.dart';

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

final _boolean = _summary('UCme', 'Boolean');
final _work = _summary(
  'UCwork',
  'Work Channel',
  more: const [
    TakeoutChannel(
      channelId: 'UCwork2',
      title: 'Work Podcast',
      isMain: false,
      listed: true,
    ),
  ],
);

void main() {
  late List<(String, String)> viewed;
  late List<String> removed, removedSignIns;

  Future<void> pump(
    WidgetTester tester, {
    bool deletionRunning = false,
    List<SignInProfile> otherSignIns = const [],
  }) {
    viewed = [];
    removed = [];
    removedSignIns = [];
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OtherAccountsSection(
              viewedAccount: _boolean,
              accounts: [
                OtherAccount(
                  summary: _work,
                  profile: const SignInProfile(
                    channelId: 'UCwork',
                    displayName: 'Ada at Work',
                    email: 'ada@work.example',
                  ),
                ),
              ],
              deletionRunning: deletionRunning,
              onView: (takeoutId, channelId) =>
                  viewed.add((takeoutId, channelId)),
              planRemoval: (id) async => TakeoutRemoval(
                summary: id == 'UCwork' ? _work : _boolean,
                orphanedChannelIds: {id},
                queuedCount: 3,
                signInIds: {id},
              ),
              onRemove: (removal) => removed.add(removal.summary.id),
              otherSignIns: otherSignIns,
              onRemoveSignIn: removedSignIns.add,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('lists the other accounts by their Google account', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Other Google accounts'), findsOneWidget);
    expect(find.text('Ada at Work'), findsOneWidget);
    expect(find.text('ada@work.example'), findsOneWidget);
    expect(
      find.textContaining('2 channels · 1,234 comments · 56 live chats'),
      findsOneWidget,
    );
    // Its channels show only once opened.
    expect(find.text('Work Podcast'), findsNothing);
  });

  testWidgets("opening an account shows its channels, to view one", (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Ada at Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work Podcast'));

    expect(viewed, [('UCwork', 'UCwork2')]);
  });

  testWidgets("while deleting, another account's channels can't be viewed", (
    tester,
  ) async {
    await pump(tester, deletionRunning: true);

    await tester.tap(find.text('Ada at Work'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work Podcast'));

    expect(viewed, isEmpty);
  });

  testWidgets('removing asks in place, saying what goes with it', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Remove takeout'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text("Remove Work Channel's takeout?"), findsOneWidget);
    expect(find.textContaining('3 queued deletions'), findsOneWidget);
    expect(
      find.textContaining('Your Google account and YouTube stay as they are'),
      findsOne,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Remove takeout'));
    await tester.pumpAndSettle();
    expect(removed, ['UCwork']);
  });

  testWidgets('cancelling the removal keeps the account', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Remove takeout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(removed, isEmpty);
    expect(find.text("Remove Work Channel's takeout?"), findsNothing);
  });

  testWidgets('the viewed account can be removed too, after asking', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Remove this takeout'));
    await tester.pumpAndSettle();
    expect(find.text("Remove Boolean's takeout?"), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Remove takeout'));
    await tester.pumpAndSettle();
    expect(removed, ['UCme']);
  });

  testWidgets("the viewed account can't be removed while deleting", (
    tester,
  ) async {
    await pump(tester, deletionRunning: true);

    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Remove this takeout'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('lists sign-ins for channels in no saved takeout', (
    tester,
  ) async {
    await pump(
      tester,
      otherSignIns: const [
        SignInProfile(channelId: 'UCelsewhere', channelTitle: 'Old Channel'),
      ],
    );

    expect(find.text('Other saved sign-ins'), findsOneWidget);
    expect(find.text('Old Channel'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Remove sign-in'));
    expect(removedSignIns, ['UCelsewhere']);
  });
}
