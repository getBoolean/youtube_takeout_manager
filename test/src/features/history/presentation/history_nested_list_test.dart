import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/category_nests.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/channel_groups.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_channel_list.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_nested_list.dart';

HistoryChannelGroup _group(String id, String title, List<int> indices) =>
    HistoryChannelGroup(
      key: id,
      channel: HistoryChannel(channelId: id, title: title),
      indices: indices,
    );

/// Gaming: Racer (videos 0, 1) and Speedy (2); Music: Singer (3).
final _nests = nestByCategory(
  [
    _group('UCr', 'Racer', [0, 1]),
    _group('UCs', 'Speedy', [2]),
    _group('UCm', 'Singer', [3]),
  ],
  picks: {
    const CategoryPick.category('Gaming'),
    const CategoryPick.category('Music'),
  },
  categoryOf: (key) =>
      key == 'UCm' ? const CategoryPath('Music') : const CategoryPath('Gaming'),
);

void main() {
  late StickyGroupedListController categories;
  late StickyGroupedListController channels;

  Future<void> show(WidgetTester tester) async {
    categories = StickyGroupedListController();
    channels = StickyGroupedListController(expandedByDefault: false);
    addTearDown(categories.dispose);
    addTearDown(channels.dispose);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HistoryNestedList(
              nests: _nests,
              categories: categories,
              channels: channels,
              scrollController: scroll,
              subscribedKeys: const {},
              pictures: const {},
              onChannelShown: (_) {},
              entryBuilder: (context, index) => Text('video $index'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder category(String label) =>
      find.widgetWithText(CategoryNestHeader, label);
  Finder channel(String title) =>
      find.widgetWithText(ChannelGroupHeader, title);

  testWidgets('categories start open, showing their channels, which start '
      'closed', (tester) async {
    await show(tester);

    // Headers are drawn more than once: in the list, and to pin.
    expect(category('Gaming'), findsWidgets);
    expect(category('Music'), findsWidgets);
    expect(channel('Racer'), findsOneWidget);
    expect(channel('Singer'), findsOneWidget);
    expect(find.text('video 0'), findsNothing);
  });

  testWidgets("a category's header tells its share, videos and channels", (
    tester,
  ) async {
    await show(tester);

    expect(
      find.descendant(
        of: category('Gaming').first,
        matching: find.textContaining('75%'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: category('Gaming').first,
        matching: find.textContaining('2 channels'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a channel opens to its videos, and closes again', (
    tester,
  ) async {
    await show(tester);

    await tester.tap(channel('Racer'));
    await tester.pumpAndSettle();
    expect(find.text('video 0'), findsOneWidget);
    expect(find.text('video 1'), findsOneWidget);
    expect(find.text('video 2'), findsNothing);

    await tester.tap(channel('Racer'));
    await tester.pumpAndSettle();
    expect(find.text('video 0'), findsNothing);
  });

  testWidgets('a category closes, hiding its channels', (tester) async {
    await show(tester);

    await tester.tap(category('Gaming').first);
    await tester.pumpAndSettle();

    expect(channel('Racer'), findsNothing);
    expect(channel('Singer'), findsOneWidget);
  });

  testWidgets('after Collapse all, opening a category shows its channels '
      'closed; Expand all opens both levels', (tester) async {
    await show(tester);
    await tester.tap(channel('Racer'));
    await tester.pumpAndSettle();

    categories.setAllExpanded(false);
    channels.setAllExpanded(false);
    await tester.pumpAndSettle();
    expect(channel('Racer'), findsNothing);

    await tester.tap(category('Gaming').first);
    await tester.pumpAndSettle();
    expect(channel('Racer'), findsOneWidget);
    expect(find.text('video 0'), findsNothing);

    categories.setAllExpanded(true);
    channels.setAllExpanded(true);
    await tester.pumpAndSettle();
    expect(find.text('video 0'), findsOneWidget);
    expect(find.text('video 3'), findsOneWidget);
  });
}
