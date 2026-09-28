import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/counted_tab_bar.dart';

const _tabs = [
  CountedTab(icon: Icons.history, label: 'Watched', count: 68),
  CountedTab(icon: Icons.search, label: 'Searches', count: 12),
  CountedTab(icon: Icons.leaderboard_outlined, label: 'Channels', count: 7),
];

Future<void> _pumpTabs(
  WidgetTester tester,
  double width, {
  List<CountedTab> tabs = _tabs,
}) async {
  tester.view.physicalSize = Size(width, 200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          bottom: CountedTabBar(
            controller: TabController(
              length: tabs.length,
              vsync: const TestVSync(),
            ),
            tabs: tabs,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

/// Every tab lies inside the window [width] wide.
void _expectAllOnScreen(WidgetTester tester, double width) {
  final tabs = find.byType(Tab);
  expect(tabs, findsNWidgets(_tabs.length));
  for (final tab in tabs.evaluate()) {
    final rect = tester.getRect(find.byWidget(tab.widget));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(width));
  }
}

void main() {
  testWidgets("shows every tab's name and count when they fit", (tester) async {
    await _pumpTabs(tester, 800);

    for (final tab in _tabs) {
      expect(find.textContaining(tab.label), findsOneWidget);
      expect(find.text('${tab.count}'), findsOneWidget);
    }
    _expectAllOnScreen(tester, 800);
  });

  testWidgets('drops the counts before the names', (tester) async {
    await _pumpTabs(tester, 500);

    for (final tab in _tabs) {
      expect(find.text(tab.label), findsOneWidget);
      expect(find.text('${tab.count}'), findsNothing);
      expect(find.byTooltip('${tab.label} (${tab.count})'), findsOneWidget);
    }
    _expectAllOnScreen(tester, 500);
  });

  testWidgets('falls back to icons with counts when names no longer fit', (
    tester,
  ) async {
    await _pumpTabs(tester, 300);

    for (final tab in _tabs) {
      expect(find.textContaining(tab.label), findsNothing);
      expect(find.byTooltip('${tab.label} (${tab.count})'), findsOneWidget);
      expect(find.byIcon(tab.icon), findsOneWidget);
      expect(find.text('${tab.count}'), findsOneWidget);
    }
    _expectAllOnScreen(tester, 300);
  });

  testWidgets("drops the counts too when even they don't fit", (tester) async {
    await _pumpTabs(tester, 150);

    for (final tab in _tabs) {
      expect(find.byTooltip('${tab.label} (${tab.count})'), findsOneWidget);
      expect(find.byIcon(tab.icon), findsOneWidget);
      expect(find.text('${tab.count}'), findsNothing);
    }
    _expectAllOnScreen(tester, 150);
  });

  testWidgets('counts are grouped by thousands', (tester) async {
    await _pumpTabs(
      tester,
      800,
      tabs: const [
        CountedTab(icon: Icons.history, label: 'Watched', count: 69193),
        CountedTab(icon: Icons.search, label: 'Searches', count: 8296),
        CountedTab(
          icon: Icons.leaderboard_outlined,
          label: 'Channels',
          count: 7,
        ),
      ],
    );

    expect(find.text('69,193'), findsOneWidget);
    expect(find.text('8,296'), findsOneWidget);
    expect(find.byTooltip('Watched (69,193)'), findsNothing);
  });
}
