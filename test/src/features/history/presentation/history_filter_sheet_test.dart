import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/presentation/category_colors.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_filter_sheet.dart';

/// Gaming's AI-made sub-category, Speedrun games.
class _Custom extends CustomCategories {
  @override
  Future<Map<String, List<SubCategory>>> build() async => const {
    'Gaming': [SubCategory(name: 'Speedrun games')],
  };
}

class _Pictures extends ChannelThumbnails {
  @override
  Future<Map<String, String>> build() async => const {};
}

const _gaming = CategoryPick.category('Gaming');
const _music = CategoryPick.category('Music');

CategoryShare _sub(String parent, String child) => CategoryShare(
  pick: CategoryPick.of(CategoryPath(parent, child)),
  watchCount: 10,
  channelCount: 1,
  share: 0.2,
);

final _mix = [
  CategoryShare(
    pick: _gaming,
    watchCount: 30,
    channelCount: 2,
    share: 0.6,
    children: [_sub('Gaming', 'Action game'), _sub('Gaming', 'Racing game')],
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
    List<CategoryShare>? mix,
    List<FilterChannel>? channels,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final result = _Result();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelThumbnailsProvider.overrideWith(_Pictures.new),
          customCategoriesProvider.overrideWith(_Custom.new),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result.draft = await showHistoryFilterSheet(
                  context,
                  initial: initial,
                  channels: channels ?? _channels,
                  hasSubscriptions: false,
                  hasShorts: false,
                  hasMusic: false,
                  mix: mix ?? _mix,
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

  group('the Categories page', () {
    Finder row(CategoryPick pick, {bool built = false}) =>
        find.byKey(HistoryFilterSheet.categoryKey(pick), skipOffstage: !built);
    final racing = CategoryPick.of(const CategoryPath('Gaming', 'Racing game'));

    testWidgets('finds a sub-category by its name, opening its category', (
      tester,
    ) async {
      await open(tester);
      await tap(tester, HistoryFilterSheet.categoriesRowKey);
      expect(row(racing), findsNothing);

      await tester.enterText(
        find.byKey(HistoryFilterSheet.categorySearchKey),
        'racing',
      );
      await tester.pumpAndSettle();

      expect(row(racing), findsOneWidget);
      expect(row(_gaming), findsOneWidget);
      expect(row(_music), findsNothing);
    });

    testWidgets("Clear clears only the categories picked", (tester) async {
      final result = await open(
        tester,
        initial: (
          subscription: SubscriptionFilter.all,
          shorts: ShowFilter.all,
          music: ShowFilter.all,
          selection: ChannelSelection(
            categories: {_gaming},
            tags: const {'Retro'},
            channels: {'UCa': _channels.first.channel},
          ),
        ),
      );
      await tap(tester, HistoryFilterSheet.categoriesRowKey);

      await tap(tester, HistoryFilterSheet.pageClearKey);
      await tap(tester, HistoryFilterSheet.showKey);

      expect(result.draft?.selection.categories, isEmpty);
      expect(result.draft?.selection.tags, {'Retro'});
      expect(result.draft?.selection.channels.keys, ['UCa']);
    });

    testWidgets('Back keeps what was picked', (tester) async {
      final result = await open(tester);
      await tap(tester, HistoryFilterSheet.categoriesRowKey);
      await tap(tester, HistoryFilterSheet.categoryKey(_music));

      await tap(tester, HistoryFilterSheet.backKey);

      expect(
        within(HistoryFilterSheet.categoriesRowKey, 'Music'),
        findsOneWidget,
      );
      await tap(tester, HistoryFilterSheet.showKey);
      expect(result.draft?.selection.categories, {_music});
    });

    testWidgets('marks the sub-categories AI made', (tester) async {
      final speedruns = CategoryPick.of(
        const CategoryPath('Gaming', 'Speedrun games'),
      );
      await open(
        tester,
        mix: [
          CategoryShare(
            pick: _gaming,
            watchCount: 30,
            channelCount: 2,
            share: 1,
            children: [
              _sub('Gaming', 'Speedrun games'),
              _sub('Gaming', 'Racing game'),
            ],
          ),
        ],
      );
      await tap(tester, HistoryFilterSheet.categoriesRowKey);
      await tap(tester, HistoryFilterSheet.categoryExpandKey('Gaming'));

      expect(
        find.descendant(of: row(speedruns), matching: find.byType(AiMark)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row(racing), matching: find.byType(AiMark)),
        findsNothing,
      );
    });

    testWidgets('builds only the rows in view', (tester) async {
      final many = [
        for (var i = 0; i < 300; i++)
          CategoryShare(
            pick: CategoryPick.category('Category $i'),
            watchCount: 300 - i,
            channelCount: 1,
            share: 1 / 300,
          ),
      ];
      await open(tester, mix: many);
      await tap(tester, HistoryFilterSheet.categoriesRowKey);

      expect(row(many.first.pick, built: true), findsOneWidget);
      expect(row(many.last.pick, built: true), findsNothing);
    });
  });

  group('the Tags page', () {
    Finder row(String name) => find.byKey(HistoryFilterSheet.tagKey(name));

    testWidgets('lists the tags, the most used first', (tester) async {
      await open(
        tester,
        tags: const [
          (name: 'Retro', channels: 1, origin: NameOrigin.user),
          (name: 'Speedruns', channels: 7, origin: NameOrigin.ai),
          (name: 'Anime', channels: 3, origin: NameOrigin.ai),
        ],
      );
      await tap(tester, HistoryFilterSheet.tagsRowKey);

      final tops = [
        for (final name in ['Speedruns', 'Anime', 'Retro'])
          tester.getTopLeft(row(name)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(
        find.descendant(of: row('Speedruns'), matching: find.byType(AiMark)),
        findsOneWidget,
      );
    });

    testWidgets('finds a tag by its name', (tester) async {
      await open(tester);
      await tap(tester, HistoryFilterSheet.tagsRowKey);

      await tester.enterText(
        find.byKey(HistoryFilterSheet.tagSearchKey),
        'speed',
      );
      await tester.pumpAndSettle();

      expect(row('Speedruns'), findsOneWidget);
      expect(row('Retro'), findsNothing);
    });

    testWidgets('Clear clears only the tags picked', (tester) async {
      final result = await open(
        tester,
        initial: (
          subscription: SubscriptionFilter.all,
          shorts: ShowFilter.all,
          music: ShowFilter.all,
          selection: ChannelSelection(
            categories: {_gaming},
            tags: const {'Retro'},
          ),
        ),
      );
      await tap(tester, HistoryFilterSheet.tagsRowKey);

      await tap(tester, HistoryFilterSheet.pageClearKey);
      await tap(tester, HistoryFilterSheet.showKey);

      expect(result.draft?.selection.tags, isEmpty);
      expect(result.draft?.selection.categories, {_gaming});
    });
  });

  group('the Channels page', () {
    Finder row(String key) => find.byKey(HistoryFilterSheet.channelKey(key));

    testWidgets('finds a channel by its name, the search staying in view as '
        'the list scrolls', (tester) async {
      await open(
        tester,
        channels: [
          for (var i = 0; i < 100; i++)
            (
              channel: HistoryChannel(channelId: 'UC$i', title: 'Channel $i'),
              count: 100 - i,
              subscribed: false,
            ),
        ],
      );
      await tap(tester, HistoryFilterSheet.channelsRowKey);

      await tester.drag(row('UC3'), const Offset(0, -1500));
      await tester.pumpAndSettle();
      final search = find.byKey(HistoryFilterSheet.channelSearchKey);
      expect(search.hitTestable(), findsOneWidget);

      await tester.enterText(search, 'channel 42');
      await tester.pumpAndSettle();

      expect(row('UC42'), findsOneWidget);
      expect(row('UC41'), findsNothing);
    });

    testWidgets('Clear clears only the channels picked', (tester) async {
      final result = await open(
        tester,
        initial: (
          subscription: SubscriptionFilter.all,
          shorts: ShowFilter.all,
          music: ShowFilter.all,
          selection: ChannelSelection(
            tags: const {'Retro'},
            channels: {'UCa': _channels.first.channel},
          ),
        ),
      );
      await tap(tester, HistoryFilterSheet.channelsRowKey);

      await tap(tester, HistoryFilterSheet.pageClearKey);
      await tap(tester, HistoryFilterSheet.showKey);

      expect(result.draft?.selection.channels, isEmpty);
      expect(result.draft?.selection.tags, {'Retro'});
    });
  });
}
