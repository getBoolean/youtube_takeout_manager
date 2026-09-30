import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_meta_line.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_pane.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_grouping.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_search_query.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_shown.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_button.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/grouping_sheet.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_channel_list.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_day_list.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_filter_sheet.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_screen.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/removed_badge.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_toolbar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

WatchEntry _watch(
  String title,
  DateTime localTime, {
  String channel = 'Y',
  String? channelId,
  DateTime? removedAt,
}) => WatchEntry(
  time: localTime.toUtc(),
  kind: WatchKind.video,
  title: title,
  url: 'https://www.youtube.com/watch?v=${title.hashCode}',
  channelTitle: channel,
  channelUrl: channelId == null
      ? null
      : 'https://www.youtube.com/channel/$channelId',
  removedAt: removedAt,
);

// Local times, so days don't depend on the machine's time zone.
final _history = TakeoutHistory(
  watches: [
    _watch(
      'Café tour',
      DateTime(2026, 4, 12, 20),
      channelId: 'UCx',
      channel: 'X',
    ),
    _watch('Other', DateTime(2026, 4, 12, 9), channel: 'CAFE Channel'),
    _watch(
      'Unrelated',
      DateTime(2026, 4, 11, 9),
      channelId: 'UCx',
      channel: 'X',
    ),
  ],
  searches: [
    SearchEntry(time: DateTime(2026, 4, 12, 8).toUtc(), query: 'crème brûlée'),
    SearchEntry(time: DateTime(2026, 4, 10, 8).toUtc(), query: 'cats'),
  ],
);

class _Fixed extends TakeoutHistoryNotifier {
  _Fixed(this.history);

  final TakeoutHistory? history;

  @override
  Future<LoadedHistory?> build() async =>
      history == null ? null : LoadedHistory.of(history!);
}

/// Records the channels history asks for pictures of, and those it asks
/// for first.
class _Fetcher extends ChannelThumbnailFetcher {
  final asked = <List<String>>[];
  final askedFirst = <List<String>>[];

  @override
  void build() {}

  @override
  Future<void> fetchNow(Iterable<String> channelIds) async =>
      asked.add(channelIds.toList());

  @override
  void fetchFirst(Iterable<String> channelIds) =>
      askedFirst.add(channelIds.toList());
}

/// Twenty videos today, each from its own channel, then thirty from one
/// channel long ago: the most watched channel is far down the list.
final _longHistory = TakeoutHistory(
  watches: [
    for (var i = 0; i < 20; i++)
      _watch(
        'Recent $i',
        DateTime(2026, 4, 12, 20).subtract(Duration(minutes: i)),
        channelId: 'UCr$i',
        channel: 'R$i',
      ),
    for (var i = 0; i < 30; i++)
      _watch(
        'Old $i',
        DateTime(2025, 1, 1, 12).subtract(Duration(minutes: i)),
        channelId: 'UCtop',
        channel: 'Top',
      ),
  ],
  searches: const [],
);

class _Pictures extends ChannelThumbnails {
  _Pictures(this.pictures);

  final Map<String, String> pictures;

  @override
  Future<Map<String, String>> build() async => pictures;
}

late _Fetcher _fetcher;

/// The channel list, with only its History button, and history.
class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PageInfo(
        ChannelListRoute.name,
        builder: (_) =>
            Scaffold(appBar: AppBar(actions: const [HistoryButton()])),
      ),
      initial: true,
    ),
    AutoRoute(page: HistoryRoute.page),
  ];
}

/// Opens history showing [history] from the channel list's button.
Future<ProviderContainer> _open(
  WidgetTester tester, {
  TakeoutHistory? history,
  bool noTakeout = false,
  double width = 800,
  Map<String, String> pictures = const {},
  String? session,
  List<Subscription> subscriptions = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      takeoutHistoryProvider.overrideWith(
        () => _Fixed(noTakeout ? null : history ?? _history),
      ),
      channelThumbnailFetcherProvider.overrideWith(() => _fetcher = _Fetcher()),
      channelThumbnailsProvider.overrideWith(() => _Pictures(pictures)),
      readSessionChannelIdProvider.overrideWithValue(session),
      historySubscriptionsProvider.overrideWith(
        (ref) async => {for (final s in subscriptions) s.channelId: s},
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: _Router().config(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(HistoryButton));
  await tester.pumpAndSettle();
  return container;
}

Finder _shown(String text) =>
    find.textContaining(text, findRichText: true).hitTestable();

Future<void> _openTab(WidgetTester tester, int index) async {
  await tester.tap(find.byType(Tab).at(index));
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  // Only within modals: over the tabs it would scroll them sideways.
  if (find.byKey(key).hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Groups the watched videos by [grouping], through the Group by modal.
Future<void> _groupBy(WidgetTester tester, HistoryGrouping grouping) async {
  await _tapKey(tester, HistoryToolbar.groupByKey);
  await _tapKey(tester, GroupingSheet.optionKey(grouping));
}

Future<void> _openFilters(WidgetTester tester) =>
    _tapKey(tester, HistoryToolbar.filtersKey);

/// The header of [title]'s group, grouped by channel. The first group's
/// header has a pinned copy over it; this is the one in the list.
Finder _channelHeader(String title) => find
    .byWidgetPredicate(
      (w) => w is ChannelGroupHeader && w.group.channel?.title == title,
    )
    .first;

Subscription _subscription(String id, String title) => Subscription(
  channelId: id,
  channelUrl: 'http://www.youtube.com/channel/$id',
  channelTitle: title,
);

void main() {
  testWidgets('the History button opens the watch history, by day', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byType(HistoryScreen), findsOneWidget);
    for (final title in ['Café tour', 'Other', 'Unrelated']) {
      expect(_shown(title), findsOneWidget);
    }
    // Two days: Apr 12 and Apr 11.
    expect(
      tester.getTopLeft(_shown('Other')).dy,
      lessThan(tester.getTopLeft(_shown('Unrelated')).dy),
    );
  });

  testWidgets('the search narrows every tab', (tester) async {
    final c = await _open(tester);

    c.read(historySearchQueryProvider.notifier).update('cafe');
    await tester.pumpAndSettle();
    expect(_shown('Café tour'), findsOneWidget);
    expect(_shown('Other'), findsOneWidget);
    expect(_shown('Unrelated'), findsNothing);

    // Grouped by channel: the channel named for it, then those with
    // videos titled for it.
    await _groupBy(tester, HistoryGrouping.channel);
    expect(
      tester.getTopLeft(_channelHeader('CAFE Channel')).dy,
      lessThan(tester.getTopLeft(_channelHeader('X')).dy),
    );

    c.read(historySearchQueryProvider.notifier).update('creme');
    await _openTab(tester, 1);
    expect(_shown('crème brûlée'), findsOneWidget);
    expect(_shown('cats'), findsNothing);
  });

  testWidgets(
    "a watch's channel can be shown alone, then every channel again",
    (tester) async {
      await _open(tester);

      await tester.tap(_shown('Café tour'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      expect(find.byType(InputChip), findsOneWidget);
      expect(_shown('Café tour'), findsOneWidget);
      expect(_shown('Unrelated'), findsOneWidget);
      expect(_shown('Other'), findsNothing);

      await tester.tap(find.byTooltip('Show every channel'));
      await tester.pumpAndSettle();

      expect(find.byType(InputChip), findsNothing);
      expect(_shown('Other'), findsOneWidget);
    },
  );

  testWidgets('grouped by channel, each channel is a collapsed header that '
      'opens to the videos watched from it', (tester) async {
    await _open(tester);

    await _groupBy(tester, HistoryGrouping.channel);

    expect(_channelHeader('X'), findsOneWidget);
    expect(_channelHeader('CAFE Channel'), findsOneWidget);
    expect(_shown('Café tour'), findsNothing);
    // Jumping to a day belongs to grouping by day or month.
    expect(find.byIcon(Icons.event), findsNothing);

    await tester.tap(_channelHeader('X'));
    await tester.pumpAndSettle();

    expect(_shown('Café tour'), findsOneWidget);
    expect(_shown('Unrelated'), findsOneWidget);
    expect(_shown('Other'), findsNothing);
  });

  testWidgets('every group can be collapsed and expanded at once', (
    tester,
  ) async {
    await _open(tester);

    await _tapKey(tester, HistoryToolbar.collapseAllKey);
    expect(_shown('Café tour'), findsNothing);
    await _tapKey(tester, HistoryToolbar.expandAllKey);
    expect(_shown('Café tour'), findsOneWidget);

    await _groupBy(tester, HistoryGrouping.channel);
    await _tapKey(tester, HistoryToolbar.expandAllKey);
    expect(_shown('Café tour'), findsOneWidget);
    expect(_shown('Other'), findsOneWidget);
    await _tapKey(tester, HistoryToolbar.collapseAllKey);
    expect(_shown('Other'), findsNothing);
  });

  testWidgets('grouped by month, videos are under their month, newest first', (
    tester,
  ) async {
    await _open(
      tester,
      history: TakeoutHistory(
        watches: [
          _watch('April video', DateTime(2026, 4, 12, 9)),
          _watch('March video', DateTime(2026, 3, 30, 9)),
        ],
      ),
    );

    await _groupBy(tester, HistoryGrouping.month);

    // The newest month's header has a pinned copy over it.
    final april = find.text(formatMonth(DateTime(2026, 4))).first;
    final march = find.text(formatMonth(DateTime(2026, 3))).first;
    expect(april, findsOneWidget);
    expect(
      tester.getTopLeft(april).dy,
      lessThan(tester.getTopLeft(_shown('April video')).dy),
    );
    expect(
      tester.getTopLeft(_shown('April video')).dy,
      lessThan(tester.getTopLeft(march).dy),
    );
    expect(
      tester.getTopLeft(march).dy,
      lessThan(tester.getTopLeft(_shown('March video')).dy),
    );
  });

  testWidgets('the Filters modal narrows to subscribed channels, shown as a '
      'chip that clears it', (tester) async {
    await _open(tester, subscriptions: [_subscription('UCx', 'X')]);

    await _openFilters(tester);
    await _tapKey(
      tester,
      HistoryFilterSheet.subscriptionKey(SubscriptionFilter.subscribed),
    );
    await _tapKey(tester, HistoryFilterSheet.showKey);

    expect(_shown('Café tour'), findsOneWidget);
    expect(_shown('Other'), findsNothing);
    expect(find.byType(InputChip), findsOneWidget);

    await tester.tap(
      find
          .descendant(of: find.byType(InputChip), matching: find.byType(Icon))
          .last,
    );
    await tester.pumpAndSettle();
    expect(_shown('Other'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('picking channels in the Filters modal shows only theirs', (
    tester,
  ) async {
    await _open(tester);

    await _openFilters(tester);
    await _tapKey(tester, HistoryFilterSheet.channelKey('name:CAFE Channel'));
    await _tapKey(tester, HistoryFilterSheet.showKey);

    expect(_shown('Other'), findsOneWidget);
    expect(_shown('Café tour'), findsNothing);
    expect(find.byType(InputChip), findsOneWidget);
  });

  testWidgets('clearing the Filters modal shows everything again', (
    tester,
  ) async {
    await _open(tester);
    await _openFilters(tester);
    await _tapKey(tester, HistoryFilterSheet.channelKey('name:CAFE Channel'));
    await _tapKey(tester, HistoryFilterSheet.showKey);

    await _openFilters(tester);
    await _tapKey(tester, HistoryFilterSheet.clearKey);

    expect(_shown('Café tour'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('Shorts, YouTube Music and subscriptions are only offered when '
      'the takeout has some', (tester) async {
    await _open(tester);

    await _openFilters(tester);

    expect(find.byKey(HistoryFilterSheet.shortsSectionKey), findsNothing);
    expect(find.byKey(HistoryFilterSheet.musicSectionKey), findsNothing);
    expect(find.byKey(HistoryFilterSheet.subscriptionSectionKey), findsNothing);
  });

  testWidgets('opening history lets the work waiting for it start', (
    tester,
  ) async {
    final c = await _open(tester);

    expect(c.read(historyShownProvider), isTrue);
  });

  testWidgets('signed in, Shorts are offered before any is known, as their '
      'formats are checked', (tester) async {
    await _open(tester, session: 'UCme');

    await _openFilters(tester);

    expect(find.byKey(HistoryFilterSheet.shortsSectionKey), findsOneWidget);
  });

  testWidgets('Shorts can be shown alone', (tester) async {
    await _open(
      tester,
      history: TakeoutHistory(
        watches: [
          WatchEntry(
            time: DateTime(2026, 4, 12, 9).toUtc(),
            kind: WatchKind.video,
            title: 'A short',
            url: 'https://www.youtube.com/shorts/s1',
            channelTitle: 'Y',
          ),
          _watch('A long one', DateTime(2026, 4, 11, 9)),
        ],
      ),
    );

    await _openFilters(tester);
    await _tapKey(tester, HistoryFilterSheet.shortsKey(ShowFilter.only));
    await _tapKey(tester, HistoryFilterSheet.showKey);

    expect(_shown('A short'), findsOneWidget);
    expect(_shown('A long one'), findsNothing);
  });

  testWidgets('channels subscribed to but never watched show only when '
      'grouped by channel', (tester) async {
    await _open(tester, subscriptions: [_subscription('UCz', 'Zed')]);
    expect(_shown('Zed'), findsNothing);

    await _groupBy(tester, HistoryGrouping.channel);

    expect(_channelHeader('Zed'), findsOneWidget);
  });

  testWidgets('jumping to a day reveals its entries', (tester) async {
    final watches = [
      for (var day = 30; day >= 1; day--)
        for (var i = 0; i < 20; i++)
          _watch('Day $day video $i', DateTime(2026, 4, day, 23 - i)),
    ];
    await _open(tester, history: TakeoutHistory(watches: watches));
    expect(_shown('Day 3 video 0'), findsNothing);

    await tester.tap(find.byIcon(Icons.event));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').hitTestable());
    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pumpAndSettle();

    expect(_shown('Day 3 video 0'), findsOneWidget);
  });

  testWidgets('jumping to a day opens it when every day is collapsed', (
    tester,
  ) async {
    final watches = [
      for (var day = 30; day >= 1; day--)
        for (var i = 0; i < 20; i++)
          _watch('Day $day video $i', DateTime(2026, 4, day, 23 - i)),
    ];
    await _open(tester, history: TakeoutHistory(watches: watches));
    await _tapKey(tester, HistoryToolbar.collapseAllKey);

    await tester.tap(find.byIcon(Icons.event));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').hitTestable());
    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pumpAndSettle();

    expect(_shown('Day 3 video 0'), findsOneWidget);
  });

  testWidgets('grouped by month, jumping to a day reveals its videos', (
    tester,
  ) async {
    final watches = [
      for (var day = 30; day >= 1; day--)
        for (var i = 0; i < 20; i++)
          _watch('Day $day video $i', DateTime(2026, 4, day, 23 - i)),
    ];
    await _open(tester, history: TakeoutHistory(watches: watches));
    await _groupBy(tester, HistoryGrouping.month);
    expect(_shown('Day 3 video 0'), findsNothing);

    await tester.tap(find.byIcon(Icons.event));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').hitTestable());
    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pumpAndSettle();

    expect(_shown('Day 3 video 0'), findsOneWidget);
  });

  testWidgets('entries no longer in YouTube history are marked, still shown', (
    tester,
  ) async {
    await _open(
      tester,
      history: TakeoutHistory(
        watches: [
          _watch('Kept', DateTime(2026, 4, 12, 9)),
          _watch(
            'Gone',
            DateTime(2026, 4, 11, 9),
            removedAt: DateTime.utc(2026, 5),
          ),
        ],
      ),
    );

    expect(_shown('Gone'), findsOneWidget);
    expect(find.byType(RemovedBadge), findsOneWidget);
  });

  testWidgets('the Removed filter shows only entries no longer in YouTube '
      'history', (tester) async {
    await _open(
      tester,
      history: TakeoutHistory(
        watches: [
          _watch('Kept', DateTime(2026, 4, 12, 9)),
          _watch(
            'Gone',
            DateTime(2026, 4, 11, 9),
            removedAt: DateTime.utc(2026, 5),
          ),
        ],
      ),
    );

    expect(find.byKey(HistoryPage.removedChipKey), findsNothing);
    await tester.tap(find.byKey(HistoryPage.removedToggleKey));
    await tester.pumpAndSettle();
    expect(_shown('Gone'), findsOneWidget);
    expect(_shown('Kept'), findsNothing);
    // Every row listed was removed; the chip says so once.
    expect(find.byType(RemovedBadge), findsNothing);

    // Its chip turns it off again.
    await tester.tap(
      find
          .descendant(
            of: find.byKey(HistoryPage.removedChipKey),
            matching: find.byType(Icon),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(HistoryPage.removedChipKey), findsNothing);
    expect(_shown('Kept'), findsOneWidget);
  });

  testWidgets('history without removed entries has no Removed filter', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byKey(HistoryPage.removedToggleKey), findsNothing);
  });

  testWidgets('the actions sheet names the video it is for', (tester) async {
    await _open(tester);

    await tester.tap(_shown('Unrelated'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.textContaining('Unrelated', findRichText: true),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the calendar opens on the day shown and offers only days with '
      'history', (tester) async {
    final watches = [
      for (var day = 30; day >= 1; day--)
        if (day != 15)
          for (var i = 0; i < 20; i++)
            _watch('Day $day video $i', DateTime(2026, 4, day, 23 - i)),
    ];
    await _open(tester, history: TakeoutHistory(watches: watches));
    Future<DatePickerDialog> openCalendar() async {
      await tester.tap(find.byIcon(Icons.event));
      await tester.pumpAndSettle();
      return tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    }

    final first = await openCalendar();
    expect(first.initialDate, DateTime(2026, 4, 30));
    expect(first.selectableDayPredicate!(DateTime(2026, 4, 15)), isFalse);
    expect(first.selectableDayPredicate!(DateTime(2026, 4, 14)), isTrue);
    await tester.tap(find.text('3').hitTestable());
    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pumpAndSettle();

    final again = await openCalendar();
    expect(again.initialDate, DateTime(2026, 4, 3));
  });

  testWidgets('without a takeout, history goes back to the channels', (
    tester,
  ) async {
    await _open(tester, noTakeout: true);

    expect(find.byType(HistoryScreen), findsNothing);
    expect(find.byType(HistoryButton), findsOneWidget);
  });

  testWidgets('the deletion queue stays with the channels, not history', (
    tester,
  ) async {
    await _open(tester, width: 1300);

    expect(find.byType(DeletionQueuePane), findsNothing);
    expect(find.byType(DeletionQueueStrip), findsNothing);
  });

  testWidgets("history asks for every channel's picture, the most recently "
      'watched first', (tester) async {
    await _open(tester, history: _longHistory);

    expect(_fetcher.asked.last, [
      for (var i = 0; i < 20; i++) 'UCr$i',
      'UCtop',
    ]);
  });

  testWidgets("videos without a channel ID ask for no channel's picture", (
    tester,
  ) async {
    await _open(tester);

    // CAFE Channel's videos name no channel ID to ask for.
    expect(_fetcher.asked.last, ['UCx']);
  });

  testWidgets('the channels on screen are asked for first, not the most '
      'watched further down', (tester) async {
    await _open(tester, history: _longHistory);

    final first = {for (final ids in _fetcher.askedFirst) ...ids};
    expect(first, contains('UCr0'));
    expect(first, isNot(contains('UCtop')));
  });

  testWidgets('scrolling to older videos asks for their channels first', (
    tester,
  ) async {
    await _open(tester, history: _longHistory);

    await tester.drag(
      find
          .descendant(
            of: find.byType(HistoryDayList),
            matching: find.byType(Scrollable),
          )
          .first,
      const Offset(0, -4000),
    );
    await tester.pumpAndSettle();

    expect(_fetcher.askedFirst.last, contains('UCtop'));
  });

  testWidgets('grouped by channel, the channels on screen are asked for '
      'first', (tester) async {
    await _open(tester, history: _longHistory);
    final before = _fetcher.askedFirst.length;

    await _groupBy(tester, HistoryGrouping.channel);

    expect(_fetcher.askedFirst.skip(before).first.first, 'UCtop');
  });

  testWidgets('signed in, rows keep room for channel pictures still to come', (
    tester,
  ) async {
    await _open(tester, session: 'UCme');

    bool keepsRoom(String channel) => tester
        .widget<ChannelMetaLine>(
          find
              .byWidgetPredicate(
                (w) => w is ChannelMetaLine && w.channelName == channel,
              )
              .first,
        )
        .keepPictureSpace;
    expect(keepsRoom('X'), isTrue);
    // Its videos name no channel ID, so no picture can come for it.
    expect(keepsRoom('CAFE Channel'), isFalse);
  });

  testWidgets('signed out, rows keep no room for channel pictures', (
    tester,
  ) async {
    await _open(tester);

    expect(
      find.byWidgetPredicate((w) => w is ChannelMetaLine && w.keepPictureSpace),
      findsNothing,
    );
  });

  testWidgets('channel pictures show in the rows, the channel chip and the '
      'channel headers', (tester) async {
    const picture = 'https://yt3.example/x';
    await _open(tester, pictures: {'UCx': picture});

    expect(
      find.byWidgetPredicate(
        (w) => w is ChannelMetaLine && w.thumbnailUrl == picture,
      ),
      findsWidgets,
    );

    await _groupBy(tester, HistoryGrouping.channel);
    expect(
      find.descendant(
        of: _channelHeader('X'),
        matching: find.byWidgetPredicate(
          (w) => w is ChannelAvatar && w.thumbnailUrl == picture,
        ),
      ),
      findsOneWidget,
    );

    // Showing it alone gives it a chip, with its picture too.
    await _openFilters(tester);
    await _tapKey(tester, HistoryFilterSheet.channelKey('UCx'));
    await _tapKey(tester, HistoryFilterSheet.showKey);
    expect(
      find.descendant(
        of: find.byType(InputChip),
        matching: find.byWidgetPredicate(
          (w) => w is ChannelAvatar && w.thumbnailUrl == picture,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a takeout without history explains how to add it', (
    tester,
  ) async {
    await _open(tester, history: TakeoutHistory.empty);

    expect(find.byKey(HistoryPage.noHistoryKey), findsOneWidget);
    expect(find.byType(Tab), findsNothing);
  });
}
