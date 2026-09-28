import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_meta_line.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_pane.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_search_query.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_button.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_screen.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/removed_badge.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/top_channels_list.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
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

/// Records the channels history asks for pictures of.
class _Fetcher extends ChannelThumbnailFetcher {
  final asked = <List<String>>[];

  @override
  void build() {}

  @override
  Future<void> fetchNow(Iterable<String> channelIds) async =>
      asked.add(channelIds.toList());
}

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

    // Channels named for it, then those with videos titled for it.
    await _openTab(tester, 2);
    final channels = find.descendant(
      of: find.byType(TopChannelsList),
      matching: find.byType(ListTile),
    );
    expect(channels, findsNWidgets(2));
    expect(
      find.descendant(
        of: channels.first,
        matching: find.textContaining('CAFE Channel', findRichText: true),
      ),
      findsOneWidget,
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

  testWidgets('picking a top channel shows its watches on Watched', (
    tester,
  ) async {
    await _open(tester);
    await _openTab(tester, 2);

    // The most watched, X, is first.
    await tester.tap(
      find
          .descendant(
            of: find.byType(TopChannelsList),
            matching: find.byType(ListTile),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.byType(InputChip), findsOneWidget);
    expect(_shown('Café tour'), findsOneWidget);
    expect(_shown('Other'), findsNothing);
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

  testWidgets("history asks for its channels' pictures, the most watched "
      'first', (tester) async {
    await _open(tester);

    // CAFE Channel's videos name no channel ID to ask for.
    expect(_fetcher.asked.last, ['UCx']);
  });

  testWidgets('channel pictures show in the rows, the channel chip and the '
      'top channels', (tester) async {
    const picture = 'https://yt3.example/x';
    await _open(tester, pictures: {'UCx': picture});

    expect(
      find.byWidgetPredicate(
        (w) => w is ChannelMetaLine && w.thumbnailUrl == picture,
      ),
      findsWidgets,
    );

    await _openTab(tester, 2);
    expect(
      find.byWidgetPredicate(
        (w) => w is ChannelAvatar && w.thumbnailUrl == picture,
      ),
      findsOneWidget,
    );

    // Picking it shows its chip, with its picture too.
    await tester.tap(
      find
          .descendant(
            of: find.byType(TopChannelsList),
            matching: find.byType(ListTile),
          )
          .first,
    );
    await tester.pumpAndSettle();
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
