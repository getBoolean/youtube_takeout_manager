import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/auth_state.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_dialog.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';

const _signedIn = AuthState(
  accessToken: 'token',
  displayName: 'Ada',
  email: 'ada@example.com',
);

class _FakeAuth extends AuthNotifier {
  final AuthState? initial;
  var signInCalls = 0;

  _FakeAuth(this.initial);

  @override
  AuthState? build() => initial;

  @override
  Future<void> signIn() async {
    signInCalls++;
    state = _signedIn;
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

void main() {
  late _FakeAuth auth;
  late _FakeQuota quota;

  Future<void> pumpDialog(
    WidgetTester tester, {
    AuthState? signedIn,
    bool oauthConfigured = true,
  }) async {
    auth = _FakeAuth(signedIn);
    quota = _FakeQuota();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          quotaProvider.overrideWith(() => quota),
        ],
        child: MaterialApp(
          home: Scaffold(body: AccountDialog(oauthConfigured: oauthConfigured)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed out offers Google sign-in', (tester) async {
    await pumpDialog(tester);

    expect(find.text('Not signed in'), findsOneWidget);
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
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

  testWidgets('signed in shows the account and signs out', (tester) async {
    await pumpDialog(tester, signedIn: _signedIn);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Not signed in'), findsOneWidget);
  });

  testWidgets('shows quota usage, which is API-only', (tester) async {
    await pumpDialog(tester);

    expect(find.text('YouTube API quota'), findsOneWidget);
    expect(find.textContaining("Activity doesn't use it"), findsOneWidget);
    expect(find.text('30 / 10000 units used today'), findsOneWidget);
  });

  testWidgets('resets quota usage after confirming', (tester) async {
    await pumpDialog(tester);

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
    auth = _FakeAuth(null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          quotaProvider.overrideWith(_FakeQuota.new),
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
