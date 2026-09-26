import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/auth_state.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_outcome.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_dialog.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_flow.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/switch_takeout_dialog.dart';

const _viewed = TakeoutChannel(
  channelId: 'UCme',
  title: 'Boolean',
  isMain: true,
  listed: true,
);

const _signedIn = AuthState(
  channelId: 'UCme',
  channelTitle: 'Boolean',
  displayName: 'Ada',
  email: 'ada@example.com',
);

class _FakeAuth extends AuthNotifier {
  final AuthState? initial;
  final SignInOutcome outcome;
  var signInCalls = 0;

  _FakeAuth(this.initial, {required this.outcome});

  @override
  AuthState? build() => initial;

  @override
  Future<SignInOutcome> signIn() async {
    signInCalls++;
    if (outcome is SignedIn) state = _signedIn;
    return outcome;
  }

  @override
  Future<void> signOut() async => state = null;
}

class _FakeQuota extends QuotaNotifier {
  var resets = 0;

  @override
  Future<QuotaState> build() async => QuotaState(
    usageByOperation: {QuotaOperation.videosList: 30},
    periodStart: DateTime.utc(2026),
  );

  @override
  Future<void> resetUsage() async => resets++;
}

class _NoSavedTakeouts extends SavedTakeouts {
  @override
  Future<List<TakeoutSummary>> build() async => const [];
}

void main() {
  late _FakeAuth auth;
  late _FakeQuota quota;

  Future<void> pumpDialog(
    WidgetTester tester, {
    AuthState? signedIn,
    bool oauthConfigured = true,
    TakeoutChannel? viewed = _viewed,
    List<TakeoutChannel> channels = const [_viewed],
    SignInOutcome outcome = const SignedIn(SignInProfile(channelId: 'UCme')),
  }) async {
    auth = _FakeAuth(signedIn, outcome: outcome);
    quota = _FakeQuota();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          quotaProvider.overrideWith(() => quota),
          viewedChannelProvider.overrideWithValue(viewed),
          takeoutChannelsProvider.overrideWithValue(channels),
          savedTakeoutsProvider.overrideWith(_NoSavedTakeouts.new),
        ],
        child: MaterialApp(
          home: Scaffold(body: AccountDialog(oauthConfigured: oauthConfigured)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed out, names the viewed channel and which to choose', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text("Boolean isn't signed in"), findsOneWidget);
    expect(find.textContaining('When Google asks, choose Boolean'), findsOne);
  });

  testWidgets('signing in with the viewed channel signs it in', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Signed in as Boolean'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('signing in with another channel warns, naming both', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      outcome: const SignedInOtherChannel(
        SignInProfile(channelId: 'UCalt', channelTitle: 'Gaming Alt'),
        viewedChannelId: 'UCme',
      ),
    );

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Signed in with another channel'), findsOneWidget);
    Finder inWarning(Finder finder) => find.descendant(
      of: find.byType(SignedInOtherChannelDialog),
      matching: finder,
    );
    expect(inWarning(find.text('Gaming Alt')), findsOneWidget);
    expect(inWarning(find.text('youtube.com/channel/UCalt')), findsOneWidget);
    expect(inWarning(find.text('Boolean')), findsOneWidget);
    expect(inWarning(find.text('youtube.com/channel/UCme')), findsOneWidget);
    expect(inWarning(find.textContaining('saved for Gaming Alt')), findsOne);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in with another channel'), findsNothing);
    // Still signed out.
    expect(find.text("Boolean isn't signed in"), findsOneWidget);
  });

  testWidgets('explains an account without a YouTube channel', (tester) async {
    await pumpDialog(tester, outcome: const SignInNoChannel());

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(find.text('No YouTube channel'), findsOneWidget);
  });

  testWidgets("sign-in is disabled when it isn't configured", (tester) async {
    await pumpDialog(tester, oauthConfigured: false);

    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Sign in with Google'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text("Sign-in isn't configured"), findsOneWidget);
  });

  testWidgets('sign-in waits for a takeout to sign its channel in', (
    tester,
  ) async {
    await pumpDialog(tester, viewed: null);

    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Sign in with Google'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Import a takeout to sign in.'), findsOneWidget);
  });

  testWidgets('signed in shows the account and channel, and signs out', (
    tester,
  ) async {
    await pumpDialog(tester, signedIn: _signedIn);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('Signed in as Boolean'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text("Boolean isn't signed in"), findsOneWidget);
  });

  testWidgets('shows the viewed takeout channel, and opens the switcher', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Takeout'), findsOneWidget);
    expect(find.text('youtube.com/channel/UCme'), findsOneWidget);
    expect(find.textContaining('of 2 channels'), findsNothing);

    await tester.tap(find.text('Switch takeout'));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchTakeoutDialog), findsOneWidget);
  });

  testWidgets('says which of several channels is viewed', (tester) async {
    await pumpDialog(
      tester,
      channels: const [
        _viewed,
        TakeoutChannel(channelId: 'UCalt', isMain: false, listed: true),
      ],
    );

    expect(find.text('1 of 2 channels in this takeout'), findsOneWidget);
  });

  testWidgets('says when no takeout is imported', (tester) async {
    await pumpDialog(tester, viewed: null, channels: const []);

    expect(find.text('No takeout imported'), findsOneWidget);
  });

  testWidgets('shows quota usage, which is API-only', (tester) async {
    await pumpDialog(tester);

    expect(find.text('YouTube API quota'), findsOneWidget);
    expect(find.textContaining("Activity doesn't use it"), findsOneWidget);
    expect(find.text('30 / 10000 units used today'), findsOneWidget);
  });

  testWidgets('resets quota usage after confirming', (tester) async {
    await pumpDialog(tester);

    await tester.ensureVisible(find.text('Reset usage'));
    await tester.tap(find.text('Reset usage'));
    await tester.pumpAndSettle();
    expect(find.text('Reset Quota Usage'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(quota.resets, 1);
    expect(find.text('Quota usage reset.'), findsOneWidget);
  });

  testWidgets('clear cache asks first and can be cancelled', (tester) async {
    await pumpDialog(tester);

    await tester.ensureVisible(find.text('Clear cache'));
    await tester.tap(find.text('Clear cache'));
    await tester.pumpAndSettle();
    expect(find.text('Clear Cache'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Clear Cache'), findsNothing);
    expect(find.text('Cache cleared.'), findsNothing);
  });

  testWidgets('the account button opens the dialog', (tester) async {
    auth = _FakeAuth(null, outcome: const SignInCancelled());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          quotaProvider.overrideWith(_FakeQuota.new),
          viewedChannelProvider.overrideWithValue(_viewed),
        ],
        child: MaterialApp(
          home: Scaffold(appBar: AppBar(actions: const [AccountButton()])),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountDialog), findsOneWidget);
  });
}
