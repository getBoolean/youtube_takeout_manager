import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_notice_banner.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';

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

final _viewedSummary = TakeoutSummary(
  id: 'UCme',
  channels: const [_main, _alt],
  countsKnown: true,
);
final _workSummary = TakeoutSummary(
  id: 'UCwork',
  channels: const [
    TakeoutChannel(
      channelId: 'UCwork',
      title: 'Work Channel',
      isMain: true,
      listed: true,
    ),
    TakeoutChannel(
      channelId: 'UCwork2',
      title: 'Work Podcast',
      isMain: false,
      listed: true,
    ),
  ],
  countsKnown: true,
);

final _picked = FilePickerResult([
  PlatformFile(name: 'takeout-001.zip', size: 1, bytes: Uint8List(1)),
]);

TakeoutImportPlan _planFor(String accountId) => TakeoutImportPlan(
  accountId: accountId,
  channels: [
    TakeoutChannel(
      channelId: accountId,
      title: 'Somebody Else',
      isMain: true,
      listed: true,
    ),
  ],
  mergedData: const TakeoutData(
    comments: [],
    liveChats: [],
    subscriptionsByChannelId: {},
  ),
  csvFiles: const {},
  goneCommentIds: const {},
  goneLiveChatIds: const {},
  newlyDeletedCommentCount: 0,
  newlyDeletedLiveChatCount: 0,
  newCommentCount: 0,
  newLiveChatCount: 0,
);

class _FakeAuth extends AuthNotifier {
  final Future<SignInOutcome> Function() outcome;
  final signIns = <String?>[];
  final signOuts = <String?>[];

  _FakeAuth({required this.outcome});

  @override
  AuthState? build() => null;

  @override
  Future<SignInOutcome> signIn({String? targetChannelId}) {
    signIns.add(targetChannelId);
    return outcome();
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
  final selected = <(String, String?)>[];

  @override
  Future<TakeoutSelection?> build() async =>
      const TakeoutSelection(takeoutId: 'UCme');

  @override
  Future<void> selectChannel(String channelId) async => channels.add(channelId);

  @override
  Future<void> select(String takeoutId, {String? channelId}) async =>
      selected.add((takeoutId, channelId));
}

class _Saved extends SavedTakeouts {
  final List<TakeoutSummary> summaries;

  _Saved(this.summaries);

  @override
  Future<List<TakeoutSummary>> build() async => summaries;
}

class _Takeout extends TakeoutNotifier {
  final Set<String> saved;
  final committed = <TakeoutImportPlan>[];

  _Takeout({this.saved = const {}});

  @override
  Future<LoadedTakeout?> build() async => null;

  @override
  Future<TakeoutImportPlan> prepareImport(
    FilePickerResult picked, {
    required bool merge,
  }) async => _planFor(saved.isEmpty ? 'UCnew' : saved.first);

  @override
  Future<void> commitImport(TakeoutImportPlan plan) async =>
      committed.add(plan);

  @override
  Future<bool> hasSavedData(String accountId) async =>
      saved.contains(accountId);
}

class _Picker implements ZipPickerRepository {
  @override
  Future<FilePickerResult?> pickZips() async => _picked;
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
  late _Takeout takeout;
  late ProviderContainer container;

  Future<void> pumpDialog(
    WidgetTester tester, {
    List<TakeoutChannel> channels = const [_main, _alt],
    Map<String, SignInProfile> signIns = const {'UCme': _mainProfile},
    List<TakeoutSummary>? saved,
    Set<String> alreadySaved = const {},
    bool oauthConfigured = true,
    Future<SignInOutcome> Function()? outcome,
    DeletionProcessingState processing = DeletionProcessingState.idle,
  }) async {
    auth = _FakeAuth(outcome: outcome ?? () async => const SignInCancelled());
    quota = _FakeQuota();
    selection = _Selection();
    takeout = _Takeout(saved: alreadySaved);
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          quotaProvider.overrideWith(() => quota),
          takeoutProvider.overrideWith(() => takeout),
          takeoutChannelsProvider.overrideWithValue(channels),
          viewedChannelProvider.overrideWithValue(channels.firstOrNull),
          savedSignInsProvider.overrideWith(() => _SignIns(signIns)),
          takeoutSelectionProvider.overrideWith(() => selection),
          savedTakeoutsProvider.overrideWith(
            () => _Saved(
              saved ?? (channels.isEmpty ? const [] : [_viewedSummary]),
            ),
          ),
          zipPickerRepositoryProvider.overrideWithValue(_Picker()),
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
    container = ProviderScope.containerOf(
      tester.element(find.byType(AccountDialog)),
    );
  }

  /// No other popup opened over the account dialog.
  void expectNoPopups() {
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
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

  testWidgets('without a takeout, offers to add an account right away', (
    tester,
  ) async {
    await pumpDialog(tester, channels: const [], signIns: const {});

    expect(find.text('No takeout imported'), findsOneWidget);
    expect(find.text('Viewing'), findsNothing);
    expect(find.text("Import another account's takeout"), findsOneWidget);
  });

  testWidgets("lists the account's channels with their sign-ins", (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Viewing'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    // Collapsed until asked for.
    expect(find.text("Import another account's takeout"), findsNothing);
  });

  testWidgets('tapping a channel views it', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Gaming Alt'));
    await tester.pumpAndSettle();

    expect(selection.channels, ['UCalt']);
  });

  testWidgets('another channel chosen at sign-in shows on its row, not in a '
      'popup', (tester) async {
    await pumpDialog(
      tester,
      outcome: () async => const SignedInOtherChannel(
        SignInProfile(channelId: 'UCx', channelTitle: 'Someone Else'),
        targetChannelId: 'UCalt',
      ),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(auth.signIns, ['UCalt']);
    expectNoPopups();
    expect(find.text('Signed in with another channel'), findsOneWidget);
    Finder inBanner(Finder finder) =>
        find.descendant(of: find.byType(SignInNoticeBanner), matching: finder);
    expect(inBanner(find.text('Someone Else')), findsOneWidget);
    expect(inBanner(find.text('Gaming Alt')), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInNoticeBanner), findsNothing);
  });

  testWidgets('an account without a YouTube channel shows on the row', (
    tester,
  ) async {
    await pumpDialog(tester, outcome: () async => const SignInNoChannel());

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.text('No YouTube channel'), findsOneWidget);
  });

  testWidgets('a failed sign-in shows on the row', (tester) async {
    await pumpDialog(tester, outcome: () async => throw Exception('offline'));

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.text('Sign-in failed'), findsOneWidget);
  });

  testWidgets('a sign-in that stopped working shows on its row', (
    tester,
  ) async {
    await pumpDialog(tester);

    container
        .read(lostSignInProvider.notifier)
        .report(const SignInProfile(channelId: 'UCalt'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-in stopped working'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    expect(container.read(lostSignInProvider), isNull);
  });

  testWidgets('signs out only that channel', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.signOuts, ['UCme']);
  });

  testWidgets('while deleting, says so in place and holds off changes', (
    tester,
  ) async {
    await pumpDialog(tester, processing: DeletionProcessingState.running);

    expect(find.text('Deleting through the YouTube API'), findsOneWidget);
    expect(find.text('Pause deletion'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.tap(find.text('Gaming Alt'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(auth.signOuts, isEmpty);
    expect(selection.channels, isEmpty);
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

  testWidgets("switches to another account's channel inside the tile", (
    tester,
  ) async {
    await pumpDialog(tester, saved: [_viewedSummary, _workSummary]);

    await tester.tap(find.byTooltip('Show other Google accounts'));
    await tester.pumpAndSettle();
    expect(find.text('Other Google accounts'), findsOneWidget);

    await tester.tap(find.text('Work Channel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work Podcast'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(selection.selected, [('UCwork', 'UCwork2')]);
  });

  testWidgets('adds another account after reviewing it in place', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.byTooltip('Show other Google accounts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Import another account's takeout"));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.text('Import this takeout?'), findsOneWidget);
    expect(find.text('Somebody Else'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();

    expect(takeout.committed.single.accountId, 'UCnew');
    expect(find.text('Import this takeout?'), findsNothing);
  });

  testWidgets('refuses a takeout from an account already saved, in place', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      saved: [_viewedSummary, _workSummary],
      alreadySaved: {'UCwork'},
    );

    await tester.tap(find.byTooltip('Show other Google accounts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Import another account's takeout"));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.text('Takeout already imported'), findsOneWidget);
    expect(takeout.committed, isEmpty);

    await tester.tap(find.text('View Work Channel'));
    await tester.pumpAndSettle();
    expect(selection.selected, [('UCwork', null)]);
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
    auth = _FakeAuth(outcome: () async => const SignInCancelled());
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
