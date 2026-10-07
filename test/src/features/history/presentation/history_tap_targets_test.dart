import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_chips.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/channel_groups.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_channel_list.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_day_list.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

class _Categories extends ChannelCategories {
  @override
  Future<Map<String, ChannelCategory>> build() async => {
    'UCx': ChannelCategory(
      path: const CategoryPath('Gaming', 'Action game'),
      tags: const ['Speedruns', 'Retro'],
      decidedAt: DateTime.utc(2026, 9, 30),
    ),
  };
}

/// Lists' rows, which aren't what's checked here.
Widget _row(BuildContext context, int index) =>
    SizedBox(height: 56, child: Text('video $index'));

void main() {
  late StickyGroupedListController controller;
  late ScrollController scroll;

  setUp(() {
    controller = StickyGroupedListController();
    scroll = ScrollController();
  });
  tearDown(() {
    controller.dispose();
    scroll.dispose();
  });

  Future<void> show(WidgetTester tester, double scale, Widget list) async {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [channelCategoriesProvider.overrideWith(_Categories.new)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: list),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Checks every tap area on screen is at least 48 points each way.
  /// (Flutter's tap target guideline leaves out whatever touches a
  /// scrolling list's edge, which full-width headers always do.)
  void expectRoomToTap(WidgetTester tester) {
    final areas = find.byType(InkWell).evaluate().toList();
    expect(areas, isNotEmpty);
    for (final area in areas) {
      final size = tester.getSize(find.byWidget(area.widget));
      expect(size.height, greaterThanOrEqualTo(48), reason: '$area');
      expect(size.width, greaterThanOrEqualTo(48), reason: '$area');
    }
  }

  for (final scale in [1.0, 1.5]) {
    testWidgets('day headers are at least 48 points to tap, at ${scale}x '
        'text', (tester) async {
      await show(
        tester,
        scale,
        HistoryDayList(
          days: [
            (dayKey: 20260412, day: DateTime(2026, 4, 12), indices: [0, 1]),
            (dayKey: 20260411, day: DateTime(2026, 4, 11), indices: [2]),
          ],
          controller: controller,
          scrollController: scroll,
          noun: 'video',
          highlighted: null,
          onHighlightDone: () {},
          entryBuilder: _row,
        ),
      );

      expectRoomToTap(tester);
    });

    testWidgets('channel headers, and the category chips in them, are at '
        'least 48 points to tap, at ${scale}x text', (tester) async {
      const channel = HistoryChannel(channelId: 'UCx', title: 'X');
      await show(
        tester,
        scale,
        HistoryChannelList(
          groups: groupByChannel(
            channels: [
              WatchedChannel(
                channel: channel,
                count: 2,
                lastWatched: DateTime.utc(2026, 4, 12),
              ),
            ],
            watchChannelIndex: Int32List.fromList([0, 0]),
            watchIndices: const [0, 1],
          ),
          watchChannelIndex: Int32List.fromList([0, 0]),
          controller: controller,
          scrollController: scroll,
          subscribedKeys: const {},
          pictures: const {},
          onChannelShown: (_) {},
          headerExtra: (context, group) =>
              ChannelCategoryChips(channel: group.channel!),
          entryBuilder: _row,
        ),
      );

      expect(find.byType(ChannelCategoryChips), findsWidgets);
      expectRoomToTap(tester);
    });
  }
}
