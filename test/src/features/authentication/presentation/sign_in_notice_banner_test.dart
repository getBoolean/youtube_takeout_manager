import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_notice.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_notice_banner.dart';

const _chosen = SignInProfile(channelId: 'UCx', channelTitle: 'Someone Else');

void main() {
  late int dismissed, viewed;

  Future<void> pump(
    WidgetTester tester,
    SignInNotice notice, {
    bool canView = false,
  }) {
    dismissed = 0;
    viewed = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SignInNoticeBanner(
              notice: notice,
              targetChannelId: 'UCalt',
              targetTitle: 'Gaming Alt',
              onViewChosen: canView ? () => viewed++ : null,
              onDismiss: () => dismissed++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('another channel chosen names both, and can be dismissed', (
    tester,
  ) async {
    await pump(tester, const OtherChannelChosen(_chosen));

    expect(find.text('Signed in with another channel'), findsOneWidget);
    expect(find.text('You chose'), findsOneWidget);
    expect(find.text('Someone Else'), findsOneWidget);
    expect(find.text('Signing in for'), findsOneWidget);
    expect(find.text('Gaming Alt'), findsOneWidget);
    expect(find.textContaining('saved for Someone Else'), findsOneWidget);
    expect(find.textContaining('View '), findsNothing);

    await tester.tap(find.byTooltip('Dismiss'));
    expect(dismissed, 1);
  });

  testWidgets('offers to view the chosen channel when it can be', (
    tester,
  ) async {
    await pump(tester, const OtherChannelChosen(_chosen), canView: true);

    await tester.tap(find.text('View Someone Else'));
    expect(viewed, 1);
  });

  testWidgets('explains an account without a YouTube channel', (tester) async {
    await pump(tester, const NoYouTubeChannel());

    expect(find.text('No YouTube channel'), findsOneWidget);
    expect(find.textContaining('Nothing was saved'), findsOneWidget);
  });

  testWidgets('says why signing in failed', (tester) async {
    await pump(tester, const SignInFailed('Exception: offline'));

    expect(find.text('Sign-in failed'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('says a sign-in stopped working', (tester) async {
    await pump(tester, const SignInStoppedWorking());

    expect(find.text('Sign-in stopped working'), findsOneWidget);
    expect(find.textContaining('Sign in again'), findsOneWidget);
  });
}
