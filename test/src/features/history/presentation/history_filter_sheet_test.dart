import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_filter_sheet.dart';

class _Pictures extends ChannelThumbnails {
  @override
  Future<Map<String, String>> build() async => const {};
}

const _gaming = CategoryPick.category('Gaming');
const _music = CategoryPick.category('Music');

final _mix = [
  const CategoryShare(
    pick: _gaming,
    watchCount: 30,
    channelCount: 2,
    share: 0.6,
  ),
  const CategoryShare(
    pick: _music,
    watchCount: 20,
    channelCount: 1,
    share: 0.4,
  ),
];

final List<FilterChannel> _channels = [
  for (final (id, title) in [
    ('UCa', 'Alpha'),
    ('UCb', 'Beta'),
    ('UCc', 'Gamma'),
  ])
    (
      channel: HistoryChannel(channelId: id, title: title),
      count: 3,
      subscribed: false,
    ),
];

const List<TagUse> _tags = [
  (name: 'Speedruns', channels: 2, origin: NameOrigin.ai),
  (name: 'Retro', channels: 1, origin: NameOrigin.user),
];

/// What the sheet gave back once closed, and whether it has closed.
class _Result {
  WatchFilterDraft? draft;
  var closed = false;
}

void main() {
  Future<_Result> open(
    WidgetTester tester, {
    WatchFilterDraft initial = noWatchFilters,
    List<TagUse> tags = _tags,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final result = _Result();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [channelThumbnailsProvider.overrideWith(_Pictures.new)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result.draft = await showHistoryFilterSheet(
                  context,
                  initial: initial,
                  channels: _channels,
                  hasSubscriptions: false,
                  hasShorts: false,
                  hasMusic: false,
                  mix: _mix,
                  tags: tags,
                );
                result.closed = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return result;
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Finder within(Key row, String text) =>
      find.descendant(of: find.byKey(row), matching: find.textContaining(text));

  group('the first page', () {
    testWidgets('has a row for categories, tags and channels, each telling '
        'what is picked: the names of two, else how many', (tester) async {
      await open(
        tester,
        initial: (
          subscription: SubscriptionFilter.all,
          shorts: ShowFilter.all,
          music: ShowFilter.all,
          selection: ChannelSelection(
            categories: {_gaming},
            tags: const {'Speedruns', 'Retro'},
            channels: {for (final c in _channels) c.channel.key: c.channel},
          ),
        ),
      );

      expect(
        within(HistoryFilterSheet.categoriesRowKey, 'Gaming'),
        findsOneWidget,
      );
      expect(
        within(HistoryFilterSheet.tagsRowKey, 'Speedruns'),
        findsOneWidget,
      );
      expect(within(HistoryFilterSheet.tagsRowKey, 'Retro'), findsOneWidget);
      expect(within(HistoryFilterSheet.channelsRowKey, '3'), findsOneWidget);
      expect(within(HistoryFilterSheet.channelsRowKey, 'Alpha'), findsNothing);
    });

    testWidgets('has no row for tags while there are none', (tester) async {
      await open(tester, tags: const []);

      expect(find.byKey(HistoryFilterSheet.tagsRowKey), findsNothing);
      expect(find.byKey(HistoryFilterSheet.channelsRowKey), findsOneWidget);
    });
  });

  testWidgets('a row opens its page; Back returns to the first page, keeping '
      'what was picked there, and Show gives it', (tester) async {
    final result = await open(tester);

    await tap(tester, HistoryFilterSheet.channelsRowKey);
    await tap(tester, HistoryFilterSheet.channelKey('UCb'));
    await tap(tester, HistoryFilterSheet.backKey);

    expect(within(HistoryFilterSheet.channelsRowKey, 'Beta'), findsOneWidget);
    await tap(tester, HistoryFilterSheet.showKey);
    expect(result.draft?.selection.channels.keys, ['UCb']);
  });

  testWidgets('Clear all clears every filter and closes', (tester) async {
    final result = await open(
      tester,
      initial: (
        subscription: SubscriptionFilter.subscribed,
        shorts: ShowFilter.only,
        music: ShowFilter.all,
        selection: const ChannelSelection(tags: {'Retro'}),
      ),
    );

    await tap(tester, HistoryFilterSheet.clearKey);

    expect(result.closed, isTrue);
    expect(result.draft, noWatchFilters);
  });

  testWidgets('closing without Show changes nothing', (tester) async {
    final result = await open(tester);
    await tap(tester, HistoryFilterSheet.channelsRowKey);
    await tap(tester, HistoryFilterSheet.channelKey('UCb'));

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    expect(result.draft, isNull);
  });
}
