import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/auth_state.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_dialog.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_flow.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/cross_channel_search_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/grouped_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/search_options_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_options_state.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_result_item.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/channel_actions_header.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/channel_app_bar.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/comment_list_view.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/live_chat_list_view.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/search_options_menu_button.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/channel_list_header.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/channel_tile.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/cross_channel_result_tile.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/unknown_channel_hint.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_items_by_channel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_method_picker.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_queue_item_tile.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_pane.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_panel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_scope_dialog.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/unicode_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/debounced_search_bar.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/own_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/channel_picker_dialog.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/home_screen.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/switch_takeout_dialog.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeout_switcher.dart';
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
  AuthState? build() => const AuthState(
    channelId: 'UCme',
    channelTitle: 'A channel with a fairly long name',
    displayName: 'Somebody With A Long Name',
    email: 'somebody.with.a.long.address@example.com',
  );
}

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

class _TwoChannelTakeout extends TakeoutNotifier {
  @override
  Future<LoadedTakeout?> build() async => LoadedTakeout(
    id: 'UCme',
    data: TakeoutData(
      comments: [
        _comment,
        _comment.copyWith(commentId: 'c2', channelId: 'UCalt'),
      ],
      liveChats: const [],
      subscriptionsByChannelId: const {},
      ownChannels: const {
        'UCme': OwnChannel(
          channelId: 'UCme',
          title: 'A channel with a fairly long name',
        ),
        'UCalt': OwnChannel(channelId: 'UCalt'),
      },
    ),
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
  takeoutProvider.overrideWith(_Takeout.new),
  takeoutSelectionProvider.overrideWith(_Selection.new),
  channelsProvider.overrideWithValue(const [_channel]),
  channelByIdProvider(fixture.channelId).overrideWithValue(_channel),
  channelCommentsProvider(
    fixture.channelId,
  ).overrideWithValue([for (final g in fixture.commentGroups) ...g.items]),
  channelLiveChatsProvider(
    fixture.channelId,
  ).overrideWithValue([for (final g in fixture.liveChatGroups) ...g.items]),
  filteredSearchCommentsProvider(fixture.channelId).overrideWithValue(const []),
  filteredSearchLiveChatsProvider(
    fixture.channelId,
  ).overrideWithValue(const []),
  channelEmojiGroupsProvider(fixture.channelId).overrideWithValue(const []),
  channelUnicodeEmojisProvider(fixture.channelId).overrideWithValue([_fire]),
  crossChannelDeletableItemsProvider.overrideWithValue(const []),
  queuedItemChannelIdsProvider.overrideWithValue(const {}),
];

/// The channel page's parts, laid out as `ChannelDetailScreen` does. (The
/// screen itself needs the router.)
Widget _channelPage({required bool liveChats, required bool selecting}) {
  final selection = ValueNotifier(selecting);
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
        bottom: ChannelTabBar(
          controller: TabController(length: 2, vsync: const TestVSync()),
          commentCount: 1234,
          liveChatCount: 567,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChannelActionsHeader(
            channelId: fixture.channelId,
            selectionMode: selection,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DebouncedSearchBar(
              hintText: 'Search comments and live chats...',
              emojis: EmojiSearchConfig(
                groups: const [],
                standardEmojis: [_fire],
              ),
              onQueryChanged: (_) {},
              trailing: const [SearchOptionsMenuButton()],
            ),
          ),
          Expanded(
            child: liveChats
                ? ChannelLiveChatListView(
                    channelId: fixture.channelId,
                    selectionMode: selection,
                    scrollController: ScrollController(),
                  )
                : ChannelCommentListView(
                    channelId: fixture.channelId,
                    selectionMode: selection,
                    scrollController: ScrollController(),
                  ),
          ),
        ],
      ),
    ),
  );
}

Widget _channelListParts() => Scaffold(
  body: ListView(
    children: [
      ChannelListHeader(
        query: 'matched',
        channelCount: 12,
        matchCount: 15,
        selectionMode: ValueNotifier(false),
      ),
      ChannelListHeader(
        query: '',
        channelCount: 12,
        matchCount: 0,
        selectionMode: ValueNotifier(false),
      ),
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
      for (final selecting in [false, true])
        CrossChannelResultTile(
          item: CommentResult(_comment, channelId: fixture.channelId),
          query: 'matched',
          selectionMode: ValueNotifier(selecting),
        ),
    ],
  ),
  bottomNavigationBar: SelectionActionBar(
    selection: const DeletionTargets(commentSnippets: {'c1': 'hi'}),
    onExitSelection: () {},
  ),
);

void main() {
  void fitsAtEveryWidth(String subject, Widget Function() build) {
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
              overrides: _overrides,
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
        });
      }
    }
  }

  fitsAtEveryWidth(
    'the channel page',
    () => _channelPage(liveChats: false, selecting: false),
  );
  fitsAtEveryWidth(
    'the channel page while selecting',
    () => _channelPage(liveChats: false, selecting: true),
  );
  fitsAtEveryWidth(
    'the channel page live chats',
    () => _channelPage(liveChats: true, selecting: false),
  );
  fitsAtEveryWidth('the channel list', _channelListParts);
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
  fitsAtEveryWidth('Home', () => const HomeScreen());
  fitsAtEveryWidth(
    'the account dialog',
    () => const Scaffold(body: AccountDialog(oauthConfigured: true)),
  );
  fitsAtEveryWidth(
    'the account dialog signed in',
    () => ProviderScope(
      overrides: [authProvider.overrideWith(_SignedIn.new)],
      child: const Scaffold(body: AccountDialog(oauthConfigured: true)),
    ),
  );
  fitsAtEveryWidth(
    'the other-channel sign-in warning',
    () => const SignedInOtherChannelDialog(
      chosen: SignInProfile(
        channelId: 'UCaVeryLongChannelIdentifier12',
        channelTitle: 'A channel with a fairly long name',
      ),
      viewedChannelId: 'UCanotherLongChannelIdentifier',
      viewedTitle: 'Another channel with a long name',
    ),
  );
  fitsAtEveryWidth(
    'the no-channel dialog',
    () => const NoYouTubeChannelDialog(),
  );
  fitsAtEveryWidth(
    'the switch takeout dialog',
    () => ProviderScope(
      overrides: [savedTakeoutsProvider.overrideWith(_SavedTakeouts.new)],
      child: const Scaffold(body: SwitchTakeoutDialog()),
    ),
  );
  fitsAtEveryWidth(
    'the remove takeout dialog',
    () => RemoveTakeoutDialog(
      removal: TakeoutRemoval(
        summary: _longTakeout,
        orphanedChannelIds: const {'UCme'},
        queuedCount: 1234,
        signInIds: const {'UCme'},
      ),
    ),
  );
  fitsAtEveryWidth(
    'the deletion running dialog',
    () => const DeletionRunningDialog(),
  );
  fitsAtEveryWidth(
    'the channel picker',
    () => ChannelPickerDialog(
      channels: _longTakeout.channels,
      viewedChannelId: 'UCanotherLongChannelIdentifier',
      signedInChannelIds: const {'UCme'},
    ),
  );
  fitsAtEveryWidth(
    'Home with several channels',
    () => ProviderScope(
      overrides: [takeoutProvider.overrideWith(_TwoChannelTakeout.new)],
      child: const HomeScreen(),
    ),
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
    ),
  );

  group('ChannelTabBar', () {
    Future<void> pumpTabs(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              bottom: ChannelTabBar(
                controller: TabController(length: 2, vsync: const TestVSync()),
                commentCount: 68,
                liveChatCount: 12,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('shows the full labels when they fit', (tester) async {
      await pumpTabs(tester, 800);

      expect(find.text('Comments ('), findsOneWidget);
      expect(find.text('Live Chats ('), findsOneWidget);
    });

    testWidgets('falls back to icons, keeping both tabs on screen', (
      tester,
    ) async {
      await pumpTabs(tester, 120);

      expect(find.text('Comments ('), findsNothing);
      expect(find.byTooltip('Comments (68)'), findsOneWidget);
      expect(find.byTooltip('Live Chats (12)'), findsOneWidget);
      for (final tab in find.byType(Tab).evaluate()) {
        final rect = tester.getRect(find.byWidget(tab.widget));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(120));
      }
    });
  });

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
