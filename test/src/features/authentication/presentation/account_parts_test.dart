import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/domain/account_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_channels_section.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_account_header.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';

const _main = TakeoutChannel(
  channelId: 'UCme',
  title: 'Boolean',
  isMain: true,
  listed: true,
  commentCount: 1234,
  liveChatCount: 5,
);
const _alt = TakeoutChannel(
  channelId: 'UCalt',
  title: 'Gaming Alt',
  isMain: false,
  listed: true,
);

void main() {
  group('accountProfileFor', () {
    const altProfile = SignInProfile(channelId: 'UCalt', email: 'a@x');
    const mainProfile = SignInProfile(channelId: 'UCme', email: 'm@x');

    test("prefers the main channel's sign-in", () {
      expect(
        accountProfileFor(
          const [_main, _alt],
          {'UCalt': altProfile, 'UCme': mainProfile},
        ),
        mainProfile,
      );
    });

    test("else any of the takeout's channels", () {
      expect(
        accountProfileFor(const [_main, _alt], {'UCalt': altProfile}),
        altProfile,
      );
    });

    test('ignores sign-ins for channels outside the takeout', () {
      expect(
        accountProfileFor(
          const [_main],
          {'UCelsewhere': const SignInProfile(channelId: 'UCelsewhere')},
        ),
        isNull,
      );
    });
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  group('GoogleAccountHeader', () {
    testWidgets('shows the Google account of a sign-in', (tester) async {
      await pump(
        tester,
        GoogleAccountHeader(
          profile: const SignInProfile(
            channelId: 'UCme',
            displayName: 'Ada',
            email: 'ada@example.com',
          ),
          mainChannel: _main,
          exportedAt: DateTime(2026, 4, 12, 12),
        ),
      );

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.text('Takeout exported Apr 12, 2026'), findsOneWidget);
    });

    testWidgets('before any sign-in, shows the main channel', (tester) async {
      await pump(tester, const GoogleAccountHeader(mainChannel: _main));

      expect(find.text('Boolean'), findsOneWidget);
      expect(find.text('Not signed in with Google'), findsOneWidget);
    });

    testWidgets('without a takeout, says so', (tester) async {
      await pump(tester, const GoogleAccountHeader());

      expect(find.text('No takeout imported'), findsOneWidget);
    });
  });

  group('AccountChannelsSection', () {
    late List<String> viewed, signedIn, signedOut;

    Future<void> pumpSection(WidgetTester tester, {bool signInEnabled = true}) {
      viewed = [];
      signedIn = [];
      signedOut = [];
      return pump(
        tester,
        AccountChannelsSection(
          channels: const [_main, _alt],
          viewedChannelId: 'UCme',
          signedInChannelIds: const {'UCme'},
          signInEnabled: signInEnabled,
          onView: viewed.add,
          onSignIn: signedIn.add,
          onSignOut: signedOut.add,
        ),
      );
    }

    testWidgets("marks the viewed channel and each one's sign-in", (
      tester,
    ) async {
      await pumpSection(tester);

      expect(find.text('Channels'), findsOneWidget);
      expect(find.text('Viewing'), findsOneWidget);
      expect(find.text('1,234 comments · 5 live chats'), findsOneWidget);
      expect(find.text('Signed in'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('tapping a channel views it', (tester) async {
      await pumpSection(tester);

      await tester.tap(find.text('Gaming Alt'));
      expect(viewed, ['UCalt']);
    });

    testWidgets("signs a channel in or out from its own row", (tester) async {
      await pumpSection(tester);

      await tester.tap(find.text('Sign in'));
      await tester.tap(find.text('Sign out'));
      expect(signedIn, ['UCalt']);
      expect(signedOut, ['UCme']);
    });

    testWidgets("signing in waits for it to be configured", (tester) async {
      await pumpSection(tester, signInEnabled: false);

      final button = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Sign in'),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });
}
