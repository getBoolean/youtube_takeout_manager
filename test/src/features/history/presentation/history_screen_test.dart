import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/history/application/history_search_query.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
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

  final TakeoutHistory history;

  @override
  Future<TakeoutHistory?> build() async => history;
}

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
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      takeoutHistoryProvider.overrideWith(() => _Fixed(history ?? _history)),
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

    await _openTab(tester, 2);
    expect(_shown('CAFE Channel'), findsOneWidget);
    expect(find.text('X', findRichText: true).hitTestable(), findsNothing);

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

  testWidgets('a takeout without history explains how to add it', (
    tester,
  ) async {
    await _open(tester, history: TakeoutHistory.empty);

    expect(find.byKey(HistoryPage.noHistoryKey), findsOneWidget);
    expect(find.byType(Tab), findsNothing);
  });
}
