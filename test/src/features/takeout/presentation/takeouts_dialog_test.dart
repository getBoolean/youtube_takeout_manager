import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/app_version.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/google_cloud_client_setup.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/lost_sign_in.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/oauth_configured.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/oauth_client_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/oauth_client.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_outcome.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_account_header.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_cloud_client_form.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_cloud_section.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_cloud_setup_pages.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_notice_banner.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import 'package:youtube_takeout_manager/src/features/device_cache/application/device_cache_clearer.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/quota/presentation/quota_section.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_importer.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_export.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_request.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/skipped_rows_banner.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeouts_dialog.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

const _client = OAuthClient(
  id: '123-abc.apps.googleusercontent.com',
  secret: 'GOCSPX-abc',
);

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

final _picked = [PickedZip.bytes('takeout-001.zip', Uint8List(1))];

const _version = '9.8.7';

TakeoutImportPlan _planFor(String accountId, {bool accountAssumed = false}) =>
    TakeoutImportPlan(
      accountId: accountId,
      accountAssumed: accountAssumed,
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
      newlyDeletedCommentIds: const {},
      newlyDeletedLiveChatIds: const {},
      newCommentIds: const {},
      newLiveChatIds: const {},
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
  /// Whether selecting a takeout shows it, rather than only being noted.
  final bool shows;
  final channels = <String>[];
  final selected = <(String, String?)>[];

  _Selection({this.shows = false});

  @override
  Future<TakeoutSelection?> build() async =>
      const TakeoutSelection(takeoutId: 'UCme');

  @override
  Future<void> selectChannel(String channelId) async => channels.add(channelId);

  @override
  Future<void> select(String takeoutId, {String? channelId}) async {
    selected.add((takeoutId, channelId));
    if (shows) state = AsyncData(TakeoutSelection(takeoutId: takeoutId));
  }
}

/// The channel list, and a channel's page with the account button, which
/// opens the dialog.
class _Pages extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PageInfo(
        ChannelListRoute.name,
        builder: (_) => const Scaffold(body: Text('Channel list')),
      ),
      path: '/channels',
      initial: true,
    ),
    AutoRoute(
      page: PageInfo(
        ChannelDetailRoute.name,
        builder: (_) =>
            Scaffold(appBar: AppBar(actions: const [AccountButton()])),
      ),
      path: '/channels/:channelId',
    ),
  ];
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

  /// Whether the takeout names no account, so it's planned into the one
  /// shown.
  final bool namesNoAccount;
  final committed = <TakeoutImportPlan>[];

  _Takeout({this.saved = const {}, this.namesNoAccount = false});

  @override
  void build() {}

  /// Its plan: into the takeout shown when it names no account.
  Future<TakeoutImportPlan> _plan() async {
    if (!namesNoAccount) return _planFor(saved.isEmpty ? 'UCnew' : saved.first);
    final shown = (await ref.read(takeoutSelectionProvider.future))!.takeoutId;
    return _planFor(shown, accountAssumed: true);
  }

  @override
  Future<PreparedImport> prepareImport(
    List<PickedZip> zips, {
    required bool merge,
  }) async => (
    plan: await _plan(),
    csvFiles: const <String, Uint8List>{},
    exports: const <TakeoutExport>[],
  );

  @override
  Future<PreparedImport> prepareMerge(List<TakeoutExport> exports) async => (
    plan: await _plan(),
    csvFiles: const <String, Uint8List>{},
    exports: exports,
  );

  @override
  Future<void> commitImport(PreparedImport prepared) async =>
      committed.add(prepared.plan);

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

class _ClientSetup extends GoogleCloudClientSetup {
  var removes = 0;
  final saved = <OAuthClient>[];

  @override
  Future<void> save(OAuthClient client) async => saved.add(client);

  @override
  Future<void> remove() async {
    removes++;
  }
}

class _FakeQuota extends QuotaNotifier {
  var resets = 0;

  @override
  Future<QuotaState> build() async => QuotaState(
    usageByOperation: {QuotaOperation.videosList: 30},
    periodStart: DateTime.utc(2026),
  );

  @override
  Future<void> resetUsage() async {
    resets++;
  }
}

class _Cache extends DeviceCacheClearer {
  var clears = 0;

  @override
  void build() {}

  @override
  Future<void> clear() async {
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
  late _Pages pages;
  late _ClientSetup clientSetup;

  Future<void> pumpDialog(
    WidgetTester tester, {
    List<TakeoutChannel> channels = const [_main, _alt],
    Map<String, SignInProfile> signIns = const {'UCme': _mainProfile},
    List<TakeoutSummary>? saved,
    Set<String> alreadySaved = const {},
    OAuthClient? client = _client,
    bool clientFromBuild = false,
    Future<SignInOutcome> Function()? outcome,
    DeletionProcessingState processing = DeletionProcessingState.idle,
    LoadedTakeout? loaded,
    bool fromChannelPage = false,
    bool namesNoAccount = false,
  }) async {
    auth = _FakeAuth(outcome: outcome ?? () async => const SignInCancelled());
    quota = _FakeQuota();
    selection = _Selection(shows: fromChannelPage || namesNoAccount);
    pages = _Pages();
    takeout = _Takeout(saved: alreadySaved, namesNoAccount: namesNoAccount);
    cache = _Cache();
    clientSetup = _ClientSetup();
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_NotSignedIn.new),
          oauthConfiguredProvider.overrideWithValue(client != null),
          oauthClientProvider.overrideWith((ref) async => client),
          oauthClientRepositoryProvider.overrideWithValue(
            OAuthClientRepository(
              KvStorageService(),
              buildClient: clientFromBuild ? client : null,
            ),
          ),
          googleCloudClientSetupProvider.overrideWith(() => clientSetup),
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
          appVersionProvider.overrideWith((ref) async => _version),
        ],
        child: fromChannelPage
            ? MaterialApp.router(routerConfig: pages.config())
            : MaterialApp(
                home: const Scaffold(
                  body: SingleChildScrollView(child: TakeoutsDialog()),
                ),
              ),
      ),
    );
    await tester.pumpAndSettle();
    if (fromChannelPage) {
      pages.push(ChannelDetailRoute(channelId: 'UCme')).ignore();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AccountButton));
      await tester.pumpAndSettle();
    }
    container = ProviderScope.containerOf(
      tester.element(find.byType(TakeoutsDialog)),
    );
  }

  /// No other popup opened over the account dialog.
  void expectNoPopups() {
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  }

  testWidgets("heads with the takeout's Google account", (tester) async {
    await pumpDialog(tester);

    final header = find.byType(GoogleAccountHeader);
    expect(
      find.descendant(of: header, matching: find.textContaining('Ada')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: header,
        matching: find.textContaining('ada@example.com'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(GoogleAccountHeader.notSignedInKey), findsNothing);
  });

  testWidgets('before any sign-in, heads with the main channel', (
    tester,
  ) async {
    await pumpDialog(tester, signIns: const {});

    expect(find.byKey(GoogleAccountHeader.notSignedInKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GoogleAccountHeader),
        matching: find.textContaining(_main.displayName),
      ),
      findsOneWidget,
    );
  });

  testWidgets('without a takeout, offers to import one, with nothing else to '
      'expand', (tester) async {
    await pumpDialog(tester, channels: const [], signIns: const {});

    expect(find.byKey(GoogleAccountHeader.noTakeoutKey), findsOneWidget);
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
          skippedLiveChatRows: 7,
        ),
      ),
    );

    Finder inBanner(String text) => find.descendant(
      of: find.byType(SkippedRowsBanner),
      matching: find.textContaining(text),
    );
    expect(inBanner('3'), findsOneWidget);
    expect(inBanner('7'), findsOneWidget);
  });

  testWidgets('says nothing of unread rows when none were skipped', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.byType(SkippedRowsBanner), findsNothing);
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
    expect(
      find.byKey(SignInNoticeBanner.otherChannelChosenKey),
      findsOneWidget,
    );
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
    expect(find.byKey(SignInNoticeBanner.noYouTubeChannelKey), findsOneWidget);
  });

  testWidgets('a failed sign-in shows on the row', (tester) async {
    await pumpDialog(tester, outcome: () async => throw Exception('offline'));

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(find.byKey(SignInNoticeBanner.signInFailedKey), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
  });

  testWidgets('a sign-in that stopped working shows on its row', (
    tester,
  ) async {
    await pumpDialog(tester);

    container
        .read(lostSignInProvider.notifier)
        .report(const SignInProfile(channelId: 'UCalt'));
    await tester.pumpAndSettle();
    expect(find.byKey(SignInNoticeBanner.stoppedWorkingKey), findsOneWidget);

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

    expect(find.byKey(const ValueKey('deletion-running')), findsOneWidget);
    expect(find.text('Pause deletion'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.tap(find.text('Gaming Alt'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(auth.signOuts, isEmpty);
    expect(selection.channels, isEmpty);
  });

  testWidgets('without a Google Cloud client, the quota is hidden and '
      'setting one up is offered', (tester) async {
    await pumpDialog(tester, client: null);

    expect(find.byType(QuotaSection), findsNothing);
    expect(find.byKey(GoogleCloudSection.setUpKey), findsOneWidget);
  });

  for (final (name, target) in [
    ('its section', find.byKey(GoogleCloudSection.setUpKey)),
    ("a channel's Sign in", find.text('Sign in').first),
  ]) {
    testWidgets('without a client, $name sets one up in the same dialog, '
        'and Back comes back here', (tester) async {
      await pumpDialog(tester, client: null, fromChannelPage: true);

      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();

      expect(find.byType(TakeoutsDialog), findsNothing);
      expect(find.byKey(GoogleCloudSetupPages.nextKey), findsOneWidget);
      expect(pages.current.name, ChannelDetailRoute.name);
      expect(auth.signIns, isEmpty);

      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is WoltModalSheet),
          matching: find.byTooltip('Back'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TakeoutsDialog), findsOneWidget);
    });
  }

  testWidgets('changing the client opens it ready to edit, and saving comes '
      'back here', (tester) async {
    await pumpDialog(tester, fromChannelPage: true);

    await tester.ensureVisible(find.byKey(GoogleCloudSection.changeKey));
    await tester.tap(find.byKey(GoogleCloudSection.changeKey));
    await tester.pumpAndSettle();

    final idField = find.descendant(
      of: find.byKey(GoogleCloudClientForm.idFieldKey),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(idField).controller?.text, _client.id);
    const other = '999-other.apps.googleusercontent.com';
    await tester.enterText(idField, other);
    await tester.tap(find.byKey(GoogleCloudClientForm.saveKey));
    await tester.pumpAndSettle();

    expect(clientSetup.saved.single.id, other);
    expect(find.byType(TakeoutsDialog), findsOneWidget);
  });

  testWidgets('cancelling a change comes back here without saving', (
    tester,
  ) async {
    await pumpDialog(tester, fromChannelPage: true);

    await tester.ensureVisible(find.byKey(GoogleCloudSection.changeKey));
    await tester.tap(find.byKey(GoogleCloudSection.changeKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(GoogleCloudSetupPages.cancelKey));
    await tester.pumpAndSettle();

    expect(clientSetup.saved, isEmpty);
    expect(find.byType(TakeoutsDialog), findsOneWidget);
  });

  testWidgets('a client users set up shows, and removing it asks first', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.textContaining(_client.id), findsOneWidget);
    expect(find.byKey(GoogleCloudSection.changeKey), findsOneWidget);
    expect(find.byType(QuotaSection), findsOneWidget);

    await tester.ensureVisible(find.text('Remove client'));
    await tester.tap(find.text('Remove client'));
    await tester.pumpAndSettle();
    expect(clientSetup.removes, 0);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(clientSetup.removes, 1);
    expectNoPopups();
  });

  testWidgets("the build's own client can't be changed", (tester) async {
    await pumpDialog(tester, clientFromBuild: true);

    expect(find.byType(GoogleCloudSection), findsNothing);
    expect(find.byType(QuotaSection), findsOneWidget);
  });

  testWidgets("the client can't be changed while deleting", (tester) async {
    await pumpDialog(tester, processing: DeletionProcessingState.running);

    expect(find.textContaining(_client.id), findsOneWidget);
    expect(find.byKey(GoogleCloudSection.changeKey), findsNothing);
    expect(find.byKey(GoogleCloudSection.pausedKey), findsOneWidget);
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('add-account-review')),
        matching: find.text('Somebody Else'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();

    expect(takeout.committed.single.accountId, 'UCnew');
    expect(find.byKey(const ValueKey('add-account-review')), findsNothing);
  });

  testWidgets('a takeout from an account already saved shows that account '
      'and reviews the merge in place', (tester) async {
    await pumpDialog(
      tester,
      saved: [_viewedSummary, _workSummary],
      alreadySaved: {'UCwork'},
    );

    await tester.tap(find.text('Import a takeout'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(selection.selected, [('UCwork', null)]);
    expect(
      find.byKey(const ValueKey('add-account-merge-review')),
      findsOneWidget,
    );
    expect(takeout.committed, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();
    expect(takeout.committed.single.accountId, 'UCwork');
    expect(
      find.byKey(const ValueKey('add-account-merge-review')),
      findsNothing,
    );
  });

  testWidgets('a takeout that names no account is put into another account '
      'in place', (tester) async {
    await pumpDialog(
      tester,
      saved: [_viewedSummary, _workSummary],
      alreadySaved: {'UCme', 'UCwork'},
      namesNoAccount: true,
    );
    await tester.tap(find.text('Import a takeout'));
    await tester.pumpAndSettle();

    const work = ValueKey('import-account-UCwork');
    await tester.tap(find.byKey(work));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(selection.selected.last.$1, 'UCwork');
    expect(tester.widget<ListTile>(find.byKey(work)).selected, isTrue);

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();
    expect(takeout.committed.single.accountId, 'UCwork');
  });

  group('merging into another account from a channel page', () {
    Future<void> startMerge(WidgetTester tester) async {
      await pumpDialog(
        tester,
        saved: [_viewedSummary, _workSummary],
        alreadySaved: {'UCwork'},
        fromChannelPage: true,
      );
      await tester.tap(find.text('Import a takeout'));
      await tester.pumpAndSettle();
    }

    testWidgets('keeps the dialog and its review open while that account is '
        'shown', (tester) async {
      await startMerge(tester);

      expect(
        container.read(takeoutSelectionProvider).value?.takeoutId,
        'UCwork',
      );
      expectNoPopups();
      expect(
        find.byKey(const ValueKey('add-account-merge-review')),
        findsOneWidget,
      );
    });

    testWidgets("leaves the channel's page once merged", (tester) async {
      await startMerge(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
      await tester.pumpAndSettle();

      expect(takeout.committed.single.accountId, 'UCwork');
      expect(pages.isRouteActive(ChannelDetailRoute.name), isFalse);
    });

    testWidgets("leaves the channel's page when cancelled, since another "
        'account is shown', (tester) async {
      await startMerge(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(takeout.committed, isEmpty);
      expect(pages.isRouteActive(ChannelDetailRoute.name), isFalse);
    });
  });

  testWidgets("shows today's quota usage", (tester) async {
    await pumpDialog(tester);

    // The fake has used 30 units.
    expect(find.textContaining('${dailyQuotaLimit - 30}'), findsOneWidget);
  });

  testWidgets('resets quota usage after confirming in place', (tester) async {
    await pumpDialog(tester);

    await tester.ensureVisible(find.text('Reset usage'));
    await tester.tap(find.text('Reset usage'));
    await tester.pumpAndSettle();
    expectNoPopups();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(quota.resets, 1);
  });

  testWidgets('clears the cache after confirming in place', (tester) async {
    await pumpDialog(tester);

    await tester.ensureVisible(find.text('Clear cache'));
    await tester.tap(find.text('Clear cache'));
    await tester.pumpAndSettle();
    expectNoPopups();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expectNoPopups();
    expect(cache.clears, 1);
  });

  testWidgets('opens the licenses page over the dialog with the app version, '
      'and Back comes back here', (tester) async {
    await pumpDialog(tester, fromChannelPage: true);

    await tester.ensureVisible(find.byKey(TakeoutsDialog.licensesKey));
    await tester.tap(find.byKey(TakeoutsDialog.licensesKey));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LicensePage),
        matching: find.textContaining(_version),
      ),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsNothing);
    expect(find.byType(TakeoutsDialog), findsOneWidget);
    expect(pages.current.name, ChannelDetailRoute.name);
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
      expect(find.byTooltip('Account'), findsOneWidget);
    });
  });
}
