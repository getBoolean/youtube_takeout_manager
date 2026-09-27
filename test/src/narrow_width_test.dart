import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/counted_tab_bar.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/oauth_configured.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_notice_banner.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_notices.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_notice.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/cross_channel_search_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/grouped_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/search_options_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/selection_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_options_state.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_result_item.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/channel_actions_header.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/channel_app_bar.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/interaction_list_view.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/search_options_button.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/channel_list_header.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/channel_list_screen.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/no_takeout_views.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/channel_tile.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/cross_channel_result_tile.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/unknown_channel_hint.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_items_by_channel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_method_picker.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_queue_item_tile.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_pane.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_panel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_scope_dialog.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/unicode_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_search_config.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_search_bar.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/add_account_import.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_removal.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/add_account_section.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/other_accounts_section.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeouts_dialog.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

import 'features/channels/presentation/channel_detail/channel_list_fixture.dart'
    as fixture;

/// Windows won't size a window's content narrower than 120px.
const _widths = [120.0, 160.0, 200.0, 280.0, 400.0];
const _textScales = [1.0, 1.5];

const _channel = Channel(
  channelId: fixture.channelId,
  channelTitle: 'A channel with a fairly long name',
  commentCount: 1234,
  liveChatCount: 567,
);

final _fire = UnicodeEmoji(
  emoji: '🔥',
  shortNames: const ['fire'],
  name: 'fire',
  category: UnicodeEmojiCategory.values.first,
);

final _comment = Comment(
  commentId: 'c1',
  channelId: 'UCme',
  createdAt: DateTime(2026, 4, 6),
  price: 0,
  rawCommentText: '{"text":"a comment that matched the search"}',
  displayText: 'a comment that matched the search',
  videoId: 'v1',
);

class _Queue extends DeletionQueue {
  @override
  Future<List<DeletionQueueItem>> build() async => [
    for (final (i, status) in DeletionItemStatus.values.indexed)
      DeletionQueueItem(
        id: '$i',
        itemId: 'q$i',
        itemType: QueueItemKind.comment,
        status: status,
        displayTextSnippet: 'A queued comment, number $i',
        errorMessage: status == DeletionItemStatus.failed
            ? 'The comment was not found'
            : null,
        createdAt: DateTime(2026, 4, 6),
        authorChannelId: 'UCme',
      ),
    // Queued before channels were tracked, so the notice shows too.
    DeletionQueueItem(
      id: 'old',
      itemId: 'old',
      itemType: QueueItemKind.comment,
      status: DeletionItemStatus.pending,
      createdAt: DateTime(2026, 4, 6),
    ),
  ];
}

class _Quota extends QuotaNotifier {
  @override
  Future<QuotaState> build() async =>
      QuotaState(usageByOperation: const {}, periodStart: DateTime(2026));
}

class _SearchOptions extends SearchOptions {
  @override
  Future<SearchOptionsState> build() async => const SearchOptionsState();
}

class _Takeout extends TakeoutNotifier {
  @override
  Future<LoadedTakeout?> build() async => LoadedTakeout(
    id: 'UCme',
    data: TakeoutData(
      comments: [_comment],
      liveChats: const [],
      subscriptionsByChannelId: const {},
      skippedCommentRows: 12,
    ),
  );
}

class _SignedIn extends AuthNotifier {
  @override
  SignInProfile? build() => _longProfile;
}

class _SignIns extends SavedSignIns {
  @override
  Future<Map<String, SignInProfile>> build() async => {'UCme': _longProfile};
}

const _longProfile = SignInProfile(
  channelId: 'UCme',
  channelTitle: 'A channel with a fairly long name',
  displayName: 'Somebody With A Long Name',
  email: 'somebody.with.a.long.address@example.com',
);

final _longTakeout = TakeoutSummary(
  id: 'UCme',
  channels: const [
    TakeoutChannel(
      channelId: 'UCme',
      title: 'A channel with a fairly long name',
      isMain: true,
      listed: true,
      commentCount: 123456,
      liveChatCount: 7890,
      thumbnailUrl: 'https://yt3.example/avatar',
    ),
    TakeoutChannel(
      channelId: 'UCanotherLongChannelIdentifier',
      title: 'Another channel with a long name',
      isMain: false,
      listed: true,
    ),
  ],
  latestExportAt: DateTime(2026, 4, 12),
  countsKnown: true,
);

class _SavedTakeouts extends SavedTakeouts {
  @override
  Future<List<TakeoutSummary>> build() async => [
    _longTakeout,
    _longTakeout.copyWith(id: 'UCother'),
  ];
}

final _removal = TakeoutRemoval(
  summary: _longTakeout,
  orphanedChannelIds: const {'UCme'},
  queuedCount: 1234,
  signInIds: const {'UCme'},
);

final _longPlan = TakeoutImportPlan(
  accountId: 'UCother',
  channels: _longTakeout.channels,
  mergedData: const TakeoutData(
    comments: [],
    liveChats: [],
    subscriptionsByChannelId: {},
    skippedCommentRows: 12,
  ),
  goneCommentIds: const {},
  goneLiveChatIds: const {},
  newlyDeletedCommentIds: const {},
  newlyDeletedLiveChatIds: const {},
  newCommentIds: const {},
  newLiveChatIds: const {},
  commentCheckSkipped: DeletionCheckSkipReason.unparsedRows,
);

Widget _addAccount(AddAccountState state, {bool prominent = false}) =>
    AddAccountSection(
      state: state,
      idleLabel: prominent ? 'Select zip files' : null,
      prominent: prominent,
      enabled: true,
      onStart: () {},
      onConfirm: () {},
      onDismiss: () {},
    );

const _notices = <String, SignInNotice>{
  'UCme': OtherChannelChosen(
    SignInProfile(
      channelId: 'UCaVeryLongChannelIdentifier12',
      channelTitle: 'A channel with a fairly long name',
    ),
  ),
  'UCa': NoYouTubeChannel(),
  'UCb': SignInFailed('Exception: the connection was closed unexpectedly'),
  'UCc': SignInStoppedWorking(),
};

class _Notices extends SignInNotices {
  @override
  Map<String, SignInNotice> build() => {'UCme': _notices['UCme']!};
}

class _Deleting extends DeletionProcessing {
  @override
  DeletionProcessingState build() => DeletionProcessingState.running;
}

class _NoTakeout extends TakeoutNotifier {
  @override
  Future<LoadedTakeout?> build() async => null;
}

class _UnreadableTakeout extends TakeoutNotifier {
  @override
  Future<LoadedTakeout?> build() async => throw const FormatException(
    'The saved comments file has a row with far too few columns in it',
  );
}

/// Keeps the fake takeout's ID selected.
class _Selection extends TakeoutSelectionNotifier {
  @override
  Future<TakeoutSelection?> build() async =>
      const TakeoutSelection(takeoutId: 'UCme');
}

final List<Override> _overrides = [
  ...fixture.fixtureOverrides(),
  deletionQueueProvider.overrideWith(_Queue.new),
  quotaProvider.overrideWith(_Quota.new),
  searchOptionsProvider.overrideWith(_SearchOptions.new),
  takeoutSelectionProvider.overrideWith(_Selection.new),
  channelsProvider.overrideWithValue(const [_channel]),
  channelByIdProvider(fixture.channelId).overrideWithValue(_channel),
  channelInteractionsProvider(
    QueueItemKind.comment,
    fixture.channelId,
  ).overrideWithValue([for (final g in fixture.commentGroups) ...g.items]),
  channelInteractionsProvider(
    QueueItemKind.liveChat,
    fixture.channelId,
  ).overrideWithValue([for (final g in fixture.liveChatGroups) ...g.items]),
  for (final kind in QueueItemKind.values)
    filteredSearchInteractionsProvider(
      kind,
      fixture.channelId,
    ).overrideWithValue(const []),
  channelEmojiGroupsProvider(fixture.channelId).overrideWithValue(const []),
  channelUnicodeEmojisProvider(fixture.channelId).overrideWithValue([_fire]),
  crossChannelDeletableItemsProvider.overrideWithValue(const []),
  queuedItemChannelIdsProvider.overrideWithValue(const {}),
];

/// In selection mode from the start.
class _Selecting extends SelectionMode {
  @override
  bool build({String? channelId}) => true;
}

/// The channel page's parts, laid out as `ChannelDetailScreen` does. (The
/// screen itself needs the router.)
Widget _channelPage({required bool liveChats}) {
  return Builder(
    builder: (context) => Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: BackButton(onPressed: () {}),
        title: const ChannelTitle(
          channelName: 'A channel with a long name',
          channelUrl: 'https://www.youtube.com/channel/ch',
        ),
        actions: const [DeletionQueueIconButton(), AccountButton()],
        bottom: CountedTabBar(
          controller: TabController(length: 2, vsync: const TestVSync()),
          tabs: const [
            CountedTab(
              icon: Icons.comment_outlined,
              label: 'Comments',
              count: 1234,
            ),
            CountedTab(
              icon: Icons.chat_bubble_outline,
              label: 'Live Chats',
              count: 567,
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ChannelActionsHeader(channelId: fixture.channelId),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: EmojiSearchBar(
              hintText: 'Search comments and live chats...',
              emojis: EmojiSearchConfig(
                groups: const [],
                standardEmojis: [_fire],
              ),
              onQueryChanged: (_) {},
              trailing: const [SearchOptionsButton()],
            ),
          ),
          Expanded(
            child: ChannelInteractionListView(
              kind: liveChats ? QueueItemKind.liveChat : QueueItemKind.comment,
              channelId: fixture.channelId,
              scrollController: ScrollController(),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The Takeouts dialog with sign-in configured, and [overrides].
Widget _takeoutsDialog([List<Override> overrides = const []]) => ProviderScope(
  overrides: [oauthConfiguredProvider.overrideWithValue(true), ...overrides],
  child: const Scaffold(body: TakeoutsDialog()),
);

Widget _channelListParts() => Scaffold(
  body: ListView(
    children: [
      ChannelListHeader(query: 'matched', channelCount: 12, matchCount: 15),
      ChannelListHeader(query: '', channelCount: 12, matchCount: 0),
      ChannelTile(channel: _channel, onTap: () {}),
      ChannelTile(
        channel: const Channel(
          channelId: unknownChannelId,
          channelTitle: 'Unknown channel',
          commentCount: 1234,
          liveChatCount: 567,
        ),
        onTap: () {},
      ),
      CrossChannelResultTile(
        result: SearchResultItem(_comment, channelId: fixture.channelId),
        query: 'matched',
      ),
    ],
  ),
  bottomNavigationBar: SelectionActionBar(
    selection: const DeletionTargets(commentSnippets: {'c1': 'hi'}),
    onExitSelection: () {},
  ),
);

void main() {
  void fitsAtEveryWidth(
    String subject,
    Widget Function() build, {
    TakeoutNotifier Function() takeout = _Takeout.new,
    List<Override> overrides = const [],
    Future<void> Function(WidgetTester tester)? then,
  }) {
    for (final scale in _textScales) {
      for (final width in _widths) {
        testWidgets('$subject fits ${width.toInt()}px at ${scale}x text', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          // Any overflow fails the test.
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ..._overrides,
                takeoutProvider.overrideWith(takeout),
                ...overrides,
              ],
              child: MaterialApp(
                theme: AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: build(),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await then?.call(tester);
        });
      }
    }
  }

  fitsAtEveryWidth('the channel page', () => _channelPage(liveChats: false));
  fitsAtEveryWidth(
    'the channel page while selecting',
    () => _channelPage(liveChats: false),
    overrides: [
      selectionModeProvider(
        channelId: fixture.channelId,
      ).overrideWith(_Selecting.new),
    ],
  );
  fitsAtEveryWidth(
    'the channel page live chats',
    () => _channelPage(liveChats: true),
  );
  fitsAtEveryWidth('the channel list', _channelListParts);
  fitsAtEveryWidth(
    'the channel list while selecting',
    _channelListParts,
    overrides: [selectionModeProvider().overrideWith(_Selecting.new)],
  );
  fitsAtEveryWidth(
    'the unknown channel title',
    () => Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: BackButton(onPressed: () {}),
        title: const ChannelTitle(
          channelName: 'Unknown channel',
          channelUrl: null,
        ),
        actions: const [AccountButton()],
      ),
      body: const UnknownChannelHint(),
    ),
  );
  fitsAtEveryWidth(
    'the deletion queue',
    () => const Scaffold(body: DeletionQueuePanel()),
  );
  fitsAtEveryWidth(
    'Channels before any takeout',
    () => const ChannelListScreen(),
    takeout: _NoTakeout.new,
    then: (tester) async =>
        expect(find.byType(TakeoutImportPrompt), findsOneWidget),
  );
  fitsAtEveryWidth(
    "Channels when the saved takeout can't be read",
    () => const ChannelListScreen(),
    takeout: _UnreadableTakeout.new,
    then: (tester) async =>
        expect(find.byType(TakeoutLoadFailed), findsOneWidget),
  );
  fitsAtEveryWidth('the Takeouts dialog', _takeoutsDialog);
  fitsAtEveryWidth(
    'the Takeouts dialog signed in',
    () => _takeoutsDialog([
      authProvider.overrideWith(_SignedIn.new),
      savedSignInsProvider.overrideWith(_SignIns.new),
    ]),
  );
  fitsAtEveryWidth(
    'the Takeouts dialog with every account shown',
    () => _takeoutsDialog([
      takeoutChannelsProvider.overrideWithValue(const []),
      savedTakeoutsProvider.overrideWith(_SavedTakeouts.new),
    ]),
  );
  fitsAtEveryWidth(
    'the Takeouts dialog while deleting, with notices',
    () => _takeoutsDialog([
      savedSignInsProvider.overrideWith(_SignIns.new),
      deletionProcessingProvider.overrideWith(_Deleting.new),
      signInNoticesProvider.overrideWith(_Notices.new),
    ]),
  );
  fitsAtEveryWidth(
    'the Takeouts dialog asking to reset quota usage and clear the cache',
    _takeoutsDialog,
    then: (tester) async {
      for (final action in ['Reset usage', 'Clear cache']) {
        await tester.ensureVisible(find.text(action));
        await tester.tap(find.text(action));
        await tester.pump();
      }
      expect(find.text('Cancel'), findsNWidgets(2));
    },
  );
  fitsAtEveryWidth(
    'the sign-in notices',
    () => Scaffold(
      body: ListView(
        children: [
          for (final notice in _notices.values)
            SignInNoticeBanner(
              notice: notice,
              targetChannelId: 'UCanotherLongChannelIdentifier',
              targetTitle: 'Another channel with a long name',
              onViewChosen: () {},
              onDismiss: () {},
            ),
        ],
      ),
    ),
  );
  fitsAtEveryWidth(
    'another account opened',
    () => Scaffold(
      body: SingleChildScrollView(
        child: OtherAccountsSection(
          viewedAccount: _longTakeout,
          accounts: [
            OtherAccount(
              summary: _longTakeout.copyWith(id: 'UCother'),
              profile: _longProfile,
            ),
          ],
          deletionRunning: false,
          onView: (_, _) {},
          planRemoval: (_) async => _removal,
          onRemove: (_) async {},
          otherSignIns: const [_longProfile],
          onRemoveSignIn: (_) {},
        ),
      ),
    ),
    then: (tester) async {
      await tester.tap(find.text(_longProfile.displayName!));
      await tester.pumpAndSettle();
    },
  );
  fitsAtEveryWidth(
    'the remove confirmation',
    () => Scaffold(
      body: SingleChildScrollView(
        child: RemoveTakeoutConfirmation(
          removal: _removal,
          onCancel: () {},
          onConfirm: () {},
        ),
      ),
    ),
  );
  fitsAtEveryWidth(
    'adding an account',
    () => Scaffold(
      body: ListView(
        children: [
          _addAccount(const AddAccountIdle()),
          _addAccount(const AddAccountIdle(), prominent: true),
          _addAccount(const AddAccountWorking()),
          _addAccount(AddAccountReview((plan: _longPlan, csvFiles: const {}))),
          _addAccount(
            AddAccountMergeReview((plan: _longPlan, csvFiles: const {})),
          ),
          _addAccount(
            const AddAccountFailed(
              TakeoutAccountMismatchException(
                'This takeout has channels from more than one saved takeout.',
                expectedChannelIds: {'UCaVeryLongChannelIdentifier12'},
                foundChannelIds: {'UCanotherLongChannelIdentifier'},
              ),
            ),
          ),
        ],
      ),
    ),
  );
  fitsAtEveryWidth(
    'a merge review listing its new comments',
    () => Scaffold(
      body: ListView(
        children: [
          _addAccount(
            AddAccountMergeReview((
              plan: TakeoutImportPlan(
                accountId: 'UCother',
                mergedData: TakeoutData(
                  comments: [_comment],
                  liveChats: const [],
                  subscriptionsByChannelId: const {},
                ),
                goneCommentIds: const {},
                goneLiveChatIds: const {},
                newlyDeletedCommentIds: const {},
                newlyDeletedLiveChatIds: const {},
                newCommentIds: {_comment.commentId},
                newLiveChatIds: const {},
              ),
              csvFiles: const {},
            )),
          ),
        ],
      ),
    ),
    then: (tester) async {
      await tester.tap(find.byKey(const ValueKey('import-new-comments')));
      await tester.pumpAndSettle();
    },
  );
  fitsAtEveryWidth(
    'the queue dialog',
    () => const QueueScopeDialog(
      scopes: [
        QueueScope(
          icon: Icons.search,
          title: 'Matching “matched”',
          targets: DeletionTargets(commentSnippets: {'c1': 'hi'}),
        ),
      ],
    ),
  );
  fitsAtEveryWidth(
    'the delete dialog',
    () => const DeletionMethodDialog(
      itemCount: 12,
      possibleMembershipEventCount: 3,
      signedIn: true,
      deletesLeft: 200,
    ),
  );
  fitsAtEveryWidth(
    'the search options dialog',
    () => const SearchOptionsDialog(options: SearchOptionsState()),
  );

  testWidgets('narrow tiles never overflow their trailing widgets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final item = DeletionQueueItem(
      id: '1',
      itemId: 'c1',
      itemType: QueueItemKind.comment,
      status: DeletionItemStatus.inProgress,
      displayTextSnippet: 'hello',
      createdAt: DateTime(2026),
    );

    for (var width = 100.0; width <= 400; width += 10) {
      // ListTile throws when its trailing widget doesn't fit.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    ChannelTile(channel: _channel, onTap: () {}),
                    DeletionQueueItemTile(item: item, onRemove: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  });
}
