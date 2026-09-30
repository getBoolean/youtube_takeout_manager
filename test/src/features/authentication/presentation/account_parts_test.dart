import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/domain/account_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_notice.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_channels_section.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_account_header.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_notice_banner.dart';
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
      expect(find.textContaining('Apr 12, 2026'), findsOneWidget);
      expect(find.byKey(GoogleAccountHeader.notSignedInKey), findsNothing);
    });

    testWidgets('before any sign-in, shows the main channel', (tester) async {
      await pump(tester, const GoogleAccountHeader(mainChannel: _main));

      expect(find.text('Boolean'), findsOneWidget);
      expect(find.byKey(GoogleAccountHeader.notSignedInKey), findsOneWidget);
    });

    testWidgets('without a takeout, says so', (tester) async {
      await pump(tester, const GoogleAccountHeader());

      expect(find.byKey(GoogleAccountHeader.noTakeoutKey), findsOneWidget);
    });

    testWidgets('expands to show the other accounts', (tester) async {
      var toggles = 0;
      await pump(
        tester,
        GoogleAccountHeader(mainChannel: _main, onToggle: () => toggles++),
      );

      await tester.tap(find.byTooltip('Show other Google accounts'));
      expect(toggles, 1);

      await pump(
        tester,
        GoogleAccountHeader(
          mainChannel: _main,
          expanded: true,
          onToggle: () => toggles++,
        ),
      );
      await tester.tap(find.text('Boolean'));
      expect(toggles, 2);
      expect(find.byTooltip('Hide other Google accounts'), findsOneWidget);
    });
  });

  group('AccountChannelsSection', () {
    late List<String> viewed, signedIn, signedOut, dismissed, viewedChosen;

    Future<void> pumpSection(
      WidgetTester tester, {
      bool deletionRunning = false,
      Map<String, SignInNotice> notices = const {},
      Set<String> savedChannelIds = const {},
    }) {
      viewed = [];
      signedIn = [];
      signedOut = [];
      dismissed = [];
      viewedChosen = [];
      return pump(
        tester,
        AccountChannelsSection(
          channels: const [_main, _alt],
          viewedChannelId: 'UCme',
          signedInChannelIds: const {'UCme'},
          deletionRunning: deletionRunning,
          notices: notices,
          savedChannelIds: savedChannelIds,
          onView: viewed.add,
          onSignIn: signedIn.add,
          onSignOut: signedOut.add,
          onDismissNotice: dismissed.add,
          onViewChosen: viewedChosen.add,
        ),
      );
    }

    testWidgets("marks the viewed channel and each one's sign-in", (
      tester,
    ) async {
      await pumpSection(tester);

      expect(find.text('Viewing'), findsOneWidget);
      expect(find.textContaining('1,234'), findsOneWidget);
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

    testWidgets("shows a sign-in notice on its channel's row", (tester) async {
      await pumpSection(
        tester,
        notices: const {
          'UCalt': OtherChannelChosen(
            SignInProfile(channelId: 'UCx', channelTitle: 'Someone Else'),
          ),
        },
        savedChannelIds: const {'UCx'},
      );

      final banner = find.byType(SignInNoticeBanner);
      expect(banner, findsOneWidget);
      // Below Gaming Alt's name, so it's clearly about that row.
      expect(
        tester.getTopLeft(banner).dy,
        greaterThan(tester.getTopLeft(find.text('Gaming Alt').first).dy),
      );

      await tester.tap(find.text('View Someone Else'));
      await tester.tap(find.byTooltip('Dismiss'));
      expect(viewedChosen, ['UCx']);
      expect(dismissed, ['UCalt']);
    });

    testWidgets("can't view the chosen channel when no takeout has it", (
      tester,
    ) async {
      await pumpSection(
        tester,
        notices: const {
          'UCalt': OtherChannelChosen(
            SignInProfile(channelId: 'UCx', channelTitle: 'Someone Else'),
          ),
        },
      );

      expect(
        find.descendant(
          of: find.byType(SignInNoticeBanner),
          matching: find.byType(TextButton),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'while deleting, channels can be neither viewed nor signed out',
      (tester) async {
        await pumpSection(tester, deletionRunning: true);

        await tester.tap(find.text('Gaming Alt'));
        final signOut = tester.widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text('Sign out'),
            matching: find.bySubtype<ButtonStyleButton>(),
          ),
        );
        expect(viewed, isEmpty);
        expect(signOut.onPressed, isNull);
      },
    );
  });
}
