import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/lost_sign_in.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/oauth_configured.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_outcome.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_notice_banner.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import 'package:youtube_takeout_manager/src/features/device_cache/application/device_cache_clearer.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_importer.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_request.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeouts_dialog.dart';

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

final _picked = [(name: 'takeout-001.zip', bytes: Uint8List(1))];

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
  goneCommentIds: const {},
  goneLiveChatIds: const {},
  newlyDeletedCommentCount: 0,
  newlyDeletedLiveChatCount: 0,
  newCommentCount: 0,
  newLiveChatCount: 0,
);

class _NotSignedIn extends AuthNotifier {
  @override
  SignInProfile? build() => null;
}

class _FakeAuth extends SignInService {
  final Future<SignInOutcome> Function() outcome;
  final signIns = <String?>[];
  final signOuts = <String?>[];

  _FakeAuth({required this.outcome});

  @override
  void build() {}

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

class _Loaded extends TakeoutNotifier {
  final LoadedTakeout? loaded;

  _Loaded(this.loaded);

  @override
  Future<LoadedTakeout?> build() async => loaded;
}

class _Takeout extends TakeoutImporter {
  final Set<String> saved;
  final committed = <TakeoutImportPlan>[];

  _Takeout({this.saved = const {}});

  @override
  void build() {}

  @override
  Future<TakeoutImportPlan> prepareImport(
    List<PickedZip> zips, {
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
  Future<List<PickedZip>?> pickZips() async => _picked;
}

class _Processing extends DeletionProcessing {
  final DeletionProcessingState initial;

  _Processing(this.initial);

  @override
  DeletionProcessingState build() => initial;
}

class _FakeQuota extends QuotaNotifier {
  var resets = 0;
  var fail = false;

  @override
  Future<QuotaState> build() async => QuotaState(
    usageByOperation: {QuotaOperation.videosList: 30},
    periodStart: DateTime.utc(2026),
  );

  @override
  Future<void> resetUsage() async {
    if (fail) throw Exception('storage is full');
    resets++;
  }
}

class _Cache extends DeviceCacheClearer {
  var clears = 0;
  var fail = false;

  @override
  void build() {}

  @override
  Future<void> clear() async {
    if (fail) throw Exception('storage is locked');
    clears++;
  }
}

void main() {
  late _FakeAuth auth;
  late _FakeQuota quota;
  late _Selection selection;
  late _Takeout takeout;
  late _Cache cache;
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
    LoadedTakeout? loaded,
  }) async {
    auth = _FakeAuth(outcome: outcome ?? () async => const SignInCancelled());
    quota = _FakeQuota();
    selection = _Selection();
    takeout = _Takeout(saved: alreadySaved);
    cache = _Cache();
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_NotSignedIn.new),
          oauthConfiguredProvider.overrideWithValue(oauthConfigured),
          signInServiceProvider.overrideWith(() => auth),
          quotaProvider.overrideWith(() => quota),
          deviceCacheClearerProvider.overrideWith(() => cache),
          takeoutProvider.overrideWith(() => _Loaded(loaded)),
          takeoutImporterProvider.overrideWith(() => takeout),
          takeoutChannelsProvider.overrideWithValue(channels),
          viewedChannelProvider.overrideWithValue(channels.firstOrNull),
          viewedChannelIdProvider.overrideWithValue(
            channels.firstOrNull?.channelId,
          ),
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
        child: MaterialApp(home: const Scaffold(body: TakeoutsDialog())),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(TakeoutsDialog)),
    );
  }

  /// No other popup opened over the account dialog.
  void expectNoPopups() {
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  }

  testWidgets("heads with the takeout's Google account", (tester) async {
    await pumpDialog(tester);

    expect(find.text('Takeouts'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
  });

  testWidgets('before any sign-in, heads with the main channel', (
    tester,
  ) async {
    await pumpDialog(tester, signIns: const {});

    expect(find.text('Not signed in with Google'), findsOneWidget);
  });

  testWidgets('without a takeout, offers to import one, with nothing else to '
      'expand', (tester) async {
    await pumpDialog(tester, channels: const [], signIns: const {});

    expect(find.text('No takeout imported'), findsOneWidget);
    expect(find.text('Viewing'), findsNothing);
    expect(find.text('Import a takeout'), findsOneWidget);
    expect(find.byTooltip('Show other Google accounts'), findsNothing);
  });

  testWidgets("lists the account's channels with their sign-ins", (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Viewing'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('offers to import a takeout without expanding', (tester) async {
    await pumpDialog(tester);

    expect(find.text('Import a takeout'), findsOneWidget);
    // The other accounts stay collapsed until asked for.
    expect(find.text('Remove this takeout'), findsNothing);
  });

  testWidgets("says how many of the takeout's rows couldn't be read", (
    tester,
  ) async {
    await pumpDialog(
      tester,
      loaded: const LoadedTakeout(
        id: 'UCme',
        data: TakeoutData(
          comments: [],
          liveChats: [],
          subscriptionsByChannelId: {},
          skippedCommentRows: 3,
          skippedLiveChatRows: 1,
        ),
      ),
    );

    expect(find.text("Some rows couldn't be read"), findsOneWidget);
    expect(
      find.textContaining('3 comments and 1 live chat were skipped'),
      findsOneWidget,
    );
  });

  testWidgets('says nothing of unread rows when none were skipped', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text("Some rows couldn't be read"), findsNothing);
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

  testWidgets('views the channel chosen instead in its own takeout', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      saved: [_viewedSummary, _workSummary],
      outcome: () async => const SignedInOtherChannel(
        SignInProfile(channelId: 'UCwork2', channelTitle: 'Work Podcast'),
        targetChannelId: 'UCalt',
      ),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Work Podcast'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(selection.selected, [('UCwork', 'UCwork2')]);
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

    await tester.tap(find.text('Import a takeout'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.text('Import this takeout?'), findsOneWidget);
    expect(find.text('Somebody Else'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();

    expect(takeout.committed.single.accountId, 'UCnew');
    expect(find.text('Import this takeout?'), findsNothing);
  });

  testWidgets('a takeout from an account already saved is merged only if '
      'asked, in place', (tester) async {
    await pumpDialog(
      tester,
      saved: [_viewedSummary, _workSummary],
      alreadySaved: {'UCwork'},
    );

    await tester.tap(find.text('Import a takeout'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.text('Takeout already imported'), findsOneWidget);
    expect(takeout.committed, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();
    expectNoPopups();
    expect(selection.selected, [('UCwork', null)]);
    expect(find.text('Merge this takeout?'), findsOneWidget);
    expect(takeout.committed, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();
    expect(takeout.committed.single.accountId, 'UCwork');
    expect(find.text('Merge this takeout?'), findsNothing);
  });

  testWidgets('shows quota usage, which is API-only', (tester) async {
    await pumpDialog(tester);

    expect(find.text('YouTube API quota'), findsOneWidget);
    expect(find.textContaining("Activity doesn't use it"), findsOneWidget);
    expect(find.text('30 / 10000 units used today'), findsOneWidget);
  });

  testWidgets('reset usage asks in place, not in a popup, and can be '
      'cancelled', (tester) async {
    await pumpDialog(tester);

    await tester.ensureVisible(find.text('Reset usage'));
    await tester.tap(find.text('Reset usage'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(
      find.textContaining('Reset the tracked quota usage'),
      findsOneWidget,
    );
    expect(find.text('Reset usage'), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Reset the tracked quota usage'), findsNothing);
    expect(find.text('Reset usage'), findsOneWidget);
    expect(quota.resets, 0);
  });

  testWidgets('resets quota usage after confirming in place, saying so '
      'there', (tester) async {
    await pumpDialog(tester);

    await tester.ensureVisible(find.text('Reset usage'));
    await tester.tap(find.text('Reset usage'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(quota.resets, 1);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Quota usage reset.'), findsOneWidget);
    expect(find.text('Reset usage'), findsOneWidget);
  });

  testWidgets('a reset that fails says so in place', (tester) async {
    await pumpDialog(tester);
    quota.fail = true;

    await tester.ensureVisible(find.text('Reset usage'));
    await tester.tap(find.text('Reset usage'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.textContaining("Couldn't reset quota usage"), findsOneWidget);
    expect(find.text('Quota usage reset.'), findsNothing);
  });

  testWidgets('clear cache asks in place, not in a popup, and can be '
      'cancelled', (tester) async {
    await pumpDialog(tester);

    await tester.ensureVisible(find.text('Clear cache'));
    await tester.tap(find.text('Clear cache'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.textContaining('Clear cached video metadata'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Clear cached video metadata'), findsNothing);
    expect(find.text('Clear cache'), findsOneWidget);
    expect(cache.clears, 0);
  });

  testWidgets('clears the cache after confirming in place, saying so there', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.ensureVisible(find.text('Clear cache'));
    await tester.tap(find.text('Clear cache'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(cache.clears, 1);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Cache cleared.'), findsOneWidget);
  });

  testWidgets('a cache clear that fails says so in place', (tester) async {
    await pumpDialog(tester);
    cache.fail = true;

    await tester.ensureVisible(find.text('Clear cache'));
    await tester.tap(find.text('Clear cache'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.textContaining("Couldn't clear the cache"), findsOneWidget);
    expect(find.text('Cache cleared.'), findsNothing);
  });

  group('account button', () {
    Future<void> pumpButton(
      WidgetTester tester, {
      TakeoutChannel? viewed = _main,
    }) async {
      auth = _FakeAuth(outcome: () async => const SignInCancelled());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_NotSignedIn.new),
            signInServiceProvider.overrideWith(() => auth),
            quotaProvider.overrideWith(_FakeQuota.new),
            takeoutChannelsProvider.overrideWithValue([?viewed]),
            viewedChannelProvider.overrideWithValue(viewed),
            viewedChannelIdProvider.overrideWithValue(viewed?.channelId),
            savedSignInsProvider.overrideWith(() => _SignIns(const {})),
          ],
          child: MaterialApp(
            home: Scaffold(appBar: AppBar(actions: const [AccountButton()])),
          ),
        ),
      );
    }

    testWidgets('opens the dialog', (tester) async {
      await pumpButton(tester);

      await tester.tap(find.byTooltip('Account: Boolean'));
      await tester.pumpAndSettle();

      expect(find.byType(TakeoutsDialog), findsOneWidget);
    });

    testWidgets("shows and names the viewed channel's picture", (tester) async {
      await pumpButton(
        tester,
        viewed: const TakeoutChannel(
          channelId: 'UCalt',
          title: 'Gaming Alt',
          isMain: false,
          listed: true,
          thumbnailUrl: 'https://example.com/alt.jpg',
        ),
      );

      final avatar = tester.widget<ChannelAvatar>(find.byType(ChannelAvatar));
      expect(avatar.thumbnailUrl, 'https://example.com/alt.jpg');
      expect(find.byTooltip('Account: Gaming Alt'), findsOneWidget);
    });

    testWidgets("shows the channel's initial while it's signed out", (
      tester,
    ) async {
      await pumpButton(tester);

      expect(find.byType(ChannelAvatar), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('shows an account icon without a takeout', (tester) async {
      await pumpButton(tester, viewed: null);

      expect(find.byType(ChannelAvatar), findsNothing);
      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
      expect(find.byTooltip('Account'), findsOneWidget);
    });
  });
}
