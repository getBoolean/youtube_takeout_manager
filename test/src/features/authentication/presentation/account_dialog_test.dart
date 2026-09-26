import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/auth_state.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_outcome.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_dialog.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_flow.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/switch_takeout_dialog.dart';

const _main = TakeoutChannel(
  channelId: 'UCme',
  title: 'Boolean',
  isMain: true,
  listed: true,
);
const _alt = TakeoutChannel(
  channelId: 'UCalt',
  title: 'Gaming Alt',
  isMain: false,
  listed: true,
);

const _mainProfile = SignInProfile(
  channelId: 'UCme',
  channelTitle: 'Boolean',
  displayName: 'Ada',
  email: 'ada@example.com',
);

class _FakeAuth extends AuthNotifier {
  final SignInOutcome outcome;
  final signIns = <String?>[];
  final signOuts = <String?>[];

  _FakeAuth({required this.outcome});

  @override
  AuthState? build() => null;

  @override
  Future<SignInOutcome> signIn({String? targetChannelId}) async {
    signIns.add(targetChannelId);
    return outcome;
  }

  @override
  Future<void> signOut({String? channelId}) async => signOuts.add(channelId);
}

class _SignIns extends SavedSignIns {
  final Map<String, SignInProfile> profiles;

  _SignIns(this.profiles);

  @override
  Future<Map<String, SignInProfile>> build() async => profiles;
}

class _Selection extends TakeoutSelectionNotifier {
  final channels = <String>[];

  @override
  Future<TakeoutSelection?> build() async =>
      const TakeoutSelection(takeoutId: 'UCme');

  @override
  Future<void> selectChannel(String channelId) async => channels.add(channelId);
}

class _NoSavedTakeouts extends SavedTakeouts {
  @override
  Future<List<TakeoutSummary>> build() async => const [];
}

class _Processing extends DeletionProcessing {
  final DeletionProcessingState initial;

  _Processing(this.initial);

  @override
  DeletionProcessingState build() => initial;
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

void main() {
  late _FakeAuth auth;
  late _FakeQuota quota;
  late _Selection selection;

  Future<void> pumpDialog(
    WidgetTester tester, {
    List<TakeoutChannel> channels = const [_main, _alt],
    Map<String, SignInProfile> signIns = const {'UCme': _mainProfile},
    bool oauthConfigured = true,
    SignInOutcome outcome = const SignInCancelled(),
    DeletionProcessingState processing = DeletionProcessingState.idle,
  }) async {
    auth = _FakeAuth(outcome: outcome);
    quota = _FakeQuota();
    selection = _Selection();
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          quotaProvider.overrideWith(() => quota),
          takeoutChannelsProvider.overrideWithValue(channels),
          viewedChannelProvider.overrideWithValue(channels.firstOrNull),
          savedSignInsProvider.overrideWith(() => _SignIns(signIns)),
          takeoutSelectionProvider.overrideWith(() => selection),
          savedTakeoutsProvider.overrideWith(_NoSavedTakeouts.new),
          deletionProcessingProvider.overrideWith(
            () => _Processing(processing),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: AccountDialog(oauthConfigured: oauthConfigured)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("heads with the takeout's Google account", (tester) async {
    await pumpDialog(tester);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
  });

  testWidgets('before any sign-in, heads with the main channel', (
    tester,
  ) async {
    await pumpDialog(tester, signIns: const {});

    expect(find.text('Not signed in with Google'), findsOneWidget);
  });

  testWidgets('without a takeout, lists no channels', (tester) async {
    await pumpDialog(tester, channels: const [], signIns: const {});

    expect(find.text('No takeout imported'), findsOneWidget);
    expect(find.text('Channels'), findsNothing);
    expect(find.text('Switch Google account'), findsOneWidget);
  });

  testWidgets("lists the account's channels with their sign-ins", (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('Viewing'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('tapping a channel views it', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Gaming Alt'));
    await tester.pumpAndSettle();

    expect(selection.channels, ['UCalt']);
  });

  testWidgets('signs a channel in from its own row, warning naming it when '
      'another is chosen', (tester) async {
    await pumpDialog(
      tester,
      outcome: const SignedInOtherChannel(
        SignInProfile(channelId: 'UCx', channelTitle: 'Someone Else'),
        targetChannelId: 'UCalt',
      ),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(auth.signIns, ['UCalt']);
    expect(find.text('Signed in with another channel'), findsOneWidget);
    Finder inWarning(Finder finder) => find.descendant(
      of: find.byType(SignedInOtherChannelDialog),
      matching: finder,
    );
    expect(inWarning(find.text('Someone Else')), findsOneWidget);
    expect(inWarning(find.text('Gaming Alt')), findsOneWidget);
    expect(inWarning(find.text('Signing in for')), findsOneWidget);
  });

  testWidgets('explains an account without a YouTube channel', (tester) async {
    await pumpDialog(tester, outcome: const SignInNoChannel());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('No YouTube channel'), findsOneWidget);
  });

  testWidgets('signs out only that channel', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.signOuts, ['UCme']);
  });

  testWidgets("won't sign out while deleting through the API", (tester) async {
    await pumpDialog(tester, processing: DeletionProcessingState.running);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Deleting in progress'), findsOneWidget);
    expect(auth.signOuts, isEmpty);
  });

  testWidgets("sign-in is disabled when it isn't configured", (tester) async {
    await pumpDialog(tester, oauthConfigured: false);

    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Sign in'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text("Sign-in isn't configured"), findsOneWidget);
  });

  testWidgets('opens the Google account switcher', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Switch Google account'));
    await tester.pumpAndSettle();

    expect(find.byType(SwitchTakeoutDialog), findsOneWidget);
    expect(find.text('Google accounts'), findsOneWidget);
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
    auth = _FakeAuth(outcome: const SignInCancelled());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          quotaProvider.overrideWith(_FakeQuota.new),
          takeoutChannelsProvider.overrideWithValue(const [_main]),
          viewedChannelProvider.overrideWithValue(_main),
          savedSignInsProvider.overrideWith(() => _SignIns(const {})),
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
