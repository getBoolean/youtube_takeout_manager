import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/viewing_mix_provider.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_channel_selection.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_removed_filter.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_search_query.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/application/watch_filter_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_csv_codec.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/category_groups.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_csv_encoder.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_format_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video_format.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';

import '../../takeout/memory_takeout_repository.dart';

WatchEntry _watch(
  String title,
  DateTime localTime, {
  String channel = 'Some channel',
  String? channelId,
}) => WatchEntry(
  time: localTime.toUtc(),
  kind: WatchKind.video,
  title: title,
  url: 'https://www.youtube.com/watch?v=${title.hashCode}',
  channelTitle: channel,
  channelUrl: channelId == null
      ? null
      : 'https://www.youtube.com/channel/$channelId',
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
    _watch('Last', DateTime(2026, 4, 9, 9), channelId: 'UCx', channel: 'X'),
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

class _Formats extends VideoFormats {
  _Formats(this.formats);

  final Map<String, VideoFormat> formats;

  @override
  Future<Map<String, VideoFormat>> build() async => formats;
}

class _Categories extends ChannelCategories {
  _Categories(this.categories);

  final Map<String, CategoryPath?> categories;

  @override
  Future<Map<String, ChannelCategory>> build() async => {
    for (final MapEntry(:key, :value) in categories.entries)
      key: ChannelCategory(path: value, decidedAt: DateTime.utc(2026, 9, 30)),
  };
}

/// Waits for the search the filters just changed to finish.
Future<void> _settle(ProviderContainer c) =>
    c.read(historySearchProvider.future);

void main() {
  late MemoryTakeoutRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'flutter.active_takeout_account': 'UCme',
    });
    repository = MemoryTakeoutRepository();
    repository.accounts['UCme'] = encodeTakeoutCsvs(
      const TakeoutData(
        comments: [],
        liveChats: [],
        subscriptionsByChannelId: {},
      ),
    );
  });

  /// Saves the takeout as subscribed to [subscriptions].
  void subscribe(List<Subscription> subscriptions) {
    repository.accounts['UCme'] = encodeTakeoutCsvs(
      TakeoutData(
        comments: const [],
        liveChats: const [],
        subscriptionsByChannelId: {
          for (final s in subscriptions) s.channelId: s,
        },
      ),
    );
  }

  ProviderContainer container({
    TakeoutHistory? history,
    Map<String, CategoryPath?> categories = const {},
  }) {
    final c = ProviderContainer(
      overrides: [
        takeoutRepositoryProvider.overrideWithValue(repository),
        if (history != null)
          takeoutHistoryProvider.overrideWith(() => _Fixed(history)),
        channelCategoriesProvider.overrideWith(() => _Categories(categories)),
      ],
    );
    addTearDown(c.dispose);
    // Keeps the search alive, as the screen does.
    c.listen(historyResultsProvider, (_, _) {});
    return c;
  }

  /// A container showing [_history], loaded, with channels in
  /// [categories].
  Future<ProviderContainer> loaded({
    Map<String, CategoryPath?> categories = const {},
  }) async {
    final c = container(history: _history, categories: categories);
    await c.read(takeoutHistoryProvider.future);
    await c.read(channelCategoriesProvider.future);
    return c;
  }

  /// Each channel group shown, with how many videos it has.
  List<(String, int)> channelGroups(ProviderContainer c) => [
    for (final g in c.read(historyChannelGroupsProvider).groups)
      (g.channel?.title ?? g.key, g.indices.length),
  ];

  List<String?> watchTitles(ProviderContainer c) => [
    for (final day in c.read(watchDaysProvider))
      for (final i in day.indices) _history.watches[i].title,
  ];

  group('loading', () {
    test("loads the selected takeout's history", () async {
      repository.accounts['UCme']!.addAll(encodeHistoryCsvs(_history));

      final history = await container().read(takeoutHistoryProvider.future);

      expect(history!.history.watches.map((w) => w.title), [
        'Café tour',
        'Other',
        'Unrelated',
        'Last',
      ]);
      expect(history.history.searches.map((s) => s.query), [
        'crème brûlée',
        'cats',
      ]);
    });

    test('a takeout saved without history has none', () async {
      final history = await container().read(takeoutHistoryProvider.future);

      expect(history!.history.isEmpty, isTrue);
    });

    test('nothing selected means no history', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await container().read(takeoutHistoryProvider.future), isNull);
    });
  });

  test('watches are grouped by local day, newest first', () async {
    final c = await loaded();

    final days = c.read(watchDaysProvider);

    expect(
      [for (final d in days) d.day],
      [DateTime(2026, 4, 12), DateTime(2026, 4, 11), DateTime(2026, 4, 9)],
    );
    expect(watchTitles(c), ['Café tour', 'Other', 'Unrelated', 'Last']);
  });

  test(
    'the query matches titles or channels whatever their case or accents',
    () async {
      final c = await loaded();

      c.read(historySearchQueryProvider.notifier).update('cafe');
      await _settle(c);

      expect(watchTitles(c), ['Café tour', 'Other']);
    },
  );

  test("the channel filter keeps only that channel's watches", () async {
    final c = await loaded();

    c
        .read(historyChannelSelectionProvider.notifier)
        .showOnly(const HistoryChannel(channelId: 'UCx', title: 'X'));
    await _settle(c);

    expect(watchTitles(c), ['Café tour', 'Unrelated', 'Last']);
  });

  test(
    'the query and the channel filter narrow the watches together',
    () async {
      final c = await loaded();

      c
          .read(historyChannelSelectionProvider.notifier)
          .showOnly(const HistoryChannel(channelId: 'UCx', title: 'X'));
      await _settle(c);
      c.read(historySearchQueryProvider.notifier).update('cafe');
      await _settle(c);
      expect(watchTitles(c), ['Café tour']);

      c.read(historyChannelSelectionProvider.notifier).clear();
      await _settle(c);
      expect(watchTitles(c), ['Café tour', 'Other']);
    },
  );

  test('searches are grouped by day and filtered by their query', () async {
    final c = await loaded();
    List<String> queries() => [
      for (final day in c.read(searchDaysProvider))
        for (final i in day.indices) _history.searches[i].query,
    ];

    expect(c.read(searchDaysProvider), hasLength(2));
    c.read(historySearchQueryProvider.notifier).update('creme');
    await _settle(c);

    expect(queries(), ['crème brûlée']);
  });

  test(
    'watched videos are grouped by channel, the most watched first',
    () async {
      final c = await loaded();

      expect(channelGroups(c), [('X', 3), ('CAFE Channel', 1)]);
    },
  );

  test('searching, the channels named for it come first', () async {
    final c = container(
      history: TakeoutHistory(
        watches: [
          _watch(
            'Something else',
            DateTime(2026, 4, 12),
            channel: 'Mario Kart Fans',
          ),
          _watch(
            'Mario Kart record',
            DateTime(2026, 4, 11),
            channel: 'MKWorld',
          ),
          _watch(
            'Another Mario Kart record',
            DateTime(2026, 4, 10),
            channel: 'MKWorld',
          ),
          _watch(
            'Shortcat plays Mario Kart',
            DateTime(2026, 4, 9),
            channel: 'Shortcat',
          ),
          _watch(
            'Shortcat plays Tetris',
            DateTime(2026, 4, 8),
            channel: 'Shortcat',
          ),
          _watch('Unrelated', DateTime(2026, 4, 6), channel: 'Nobody'),
        ],
      ),
    );
    await c.read(takeoutHistoryProvider.future);

    c.read(historySearchQueryProvider.notifier).update('mario kart');
    await _settle(c);

    // By name with every video; the rest with the videos that match.
    expect(channelGroups(c), [
      ('Mario Kart Fans', 1),
      ('MKWorld', 2),
      ('Shortcat', 1),
    ]);
  });

  group('subscriptions', () {
    Subscription sub(String id, String title) => Subscription(
      channelId: id,
      channelUrl: 'http://www.youtube.com/channel/$id',
      channelTitle: title,
    );

    test('channels subscribed to but never watched are listed after the '
        'watched ones, with no videos', () async {
      subscribe([sub('UCx', 'X'), sub('UCz', 'Zed')]);
      final c = await loaded();
      await c.read(historySubscriptionsProvider.future);

      expect(channelGroups(c), [('X', 3), ('CAFE Channel', 1), ('Zed', 0)]);
      expect(watchTitles(c), hasLength(4));
    });

    test('the subscription filter keeps only subscribed channels, or only '
        'the others', () async {
      subscribe([sub('UCx', 'X'), sub('UCz', 'Zed')]);
      final c = await loaded();
      await c.read(historySubscriptionsProvider.future);
      final filter = c.read(historySubscriptionFilterProvider.notifier);

      filter.set(SubscriptionFilter.subscribed);
      await _settle(c);
      expect(watchTitles(c), ['Café tour', 'Unrelated', 'Last']);
      expect(channelGroups(c), [('X', 3), ('Zed', 0)]);

      filter.set(SubscriptionFilter.notSubscribed);
      await _settle(c);
      expect(watchTitles(c), ['Other']);
      expect(channelGroups(c), [('CAFE Channel', 1)]);
    });

    test('a channel never watched has nothing to show once the watched '
        'videos are narrowed to some kind', () async {
      subscribe([sub('UCz', 'Zed')]);
      final c = await loaded();
      await c.read(historySubscriptionsProvider.future);

      c.read(historyMusicFilterProvider.notifier).set(ShowFilter.only);
      await _settle(c);

      expect(channelGroups(c), isEmpty);
    });

    test('the filters offer every channel, the watched ones most watched '
        'first, then the ones subscribed to but never watched', () async {
      subscribe([sub('UCx', 'X'), sub('UCz', 'Zed')]);
      final c = await loaded();
      await c.read(historySubscriptionsProvider.future);
      // Narrowing what's shown doesn't narrow what can be picked.
      c.read(historySearchQueryProvider.notifier).update('nothing like it');
      await _settle(c);

      expect(
        [
          for (final f in c.read(historyFilterChannelsProvider))
            (f.channel.title, f.count, f.subscribed),
        ],
        [('X', 3, true), ('CAFE Channel', 1, false), ('Zed', 0, true)],
      );
    });

    test('searching lists a channel never watched only when its name '
        'matches', () async {
      subscribe([sub('UCz', 'Zed'), sub('UCc', 'Cafe crawl')]);
      final c = await loaded();
      await c.read(historySubscriptionsProvider.future);

      c.read(historySearchQueryProvider.notifier).update('cafe');
      await _settle(c);

      expect(
        [for (final (name, _) in channelGroups(c)) name],
        ['CAFE Channel', 'X', 'Cafe crawl'],
      );
    });
  });

  test('a video whose format says it is a Short counts as one', () async {
    final c = ProviderContainer(
      overrides: [
        takeoutRepositoryProvider.overrideWithValue(repository),
        takeoutHistoryProvider.overrideWith(
          () => _Fixed(
            TakeoutHistory(
              watches: [
                _watch('Tall', DateTime(2026, 4, 12, 9)),
                _watch('Wide', DateTime(2026, 4, 11, 9)),
              ],
            ),
          ),
        ),
        videoFormatsProvider.overrideWith(
          () => _Formats({
            '${'Tall'.hashCode}': const VideoFormat(
              seconds: 40,
              shape: VideoShape.tall,
            ),
          }),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(historyResultsProvider, (_, _) {});
    final loaded = (await c.read(takeoutHistoryProvider.future))!.history;
    await c.read(videoFormatsProvider.future);

    c.read(historyShortsFilterProvider.notifier).set(ShowFilter.only);
    await _settle(c);

    expect(
      [
        for (final day in c.read(watchDaysProvider))
          for (final i in day.indices) loaded.watches[i].title,
      ],
      ['Tall'],
    );
    expect(c.read(historyShortCountProvider), 1);
  });

  test('videos watched on YouTube Music can be shown alone', () async {
    final c = container(
      history: TakeoutHistory(
        watches: [
          _watch('Song', DateTime(2026, 4, 12, 9)).copyWith(music: true),
          _watch('Video', DateTime(2026, 4, 11, 9)),
        ],
      ),
    );
    final loaded = (await c.read(takeoutHistoryProvider.future))!.history;

    c.read(historyMusicFilterProvider.notifier).set(ShowFilter.only);
    await _settle(c);

    expect(
      [
        for (final day in c.read(watchDaysProvider))
          for (final i in day.indices) loaded.watches[i].title,
      ],
      ['Song'],
    );
  });

  group('categories', () {
    const action = CategoryPath('Gaming', 'Action game');
    const cooking = CategoryPath('Lifestyle', 'Cooking');

    test('picking a category shows only the videos of its channels, in '
        'every grouping', () async {
      final c = await loaded(categories: {'UCx': action});

      c
          .read(historyChannelSelectionProvider.notifier)
          .set(
            ChannelSelection(
              categories: {const CategoryPick.category('Gaming')},
            ),
          );
      await _settle(c);

      expect(watchTitles(c), ['Café tour', 'Unrelated', 'Last']);
      expect(channelGroups(c), [('X', 3)]);
    });

    test('a channel subscribed to but never watched is listed when its '
        'category is picked', () async {
      subscribe([
        Subscription(
          channelId: 'UCz',
          channelUrl: 'http://www.youtube.com/channel/UCz',
          channelTitle: 'Zed',
        ),
      ]);
      final c = await loaded(categories: {'UCx': action, 'UCz': cooking});
      await c.read(historySubscriptionsProvider.future);

      c
          .read(historyChannelSelectionProvider.notifier)
          .set(
            ChannelSelection(
              categories: {const CategoryPick.category('Lifestyle')},
            ),
          );
      await _settle(c);

      expect(channelGroups(c), [('Zed', 0)]);
      expect(watchTitles(c), isEmpty);
    });

    test('watched videos are grouped by category too, the uncategorized '
        'last', () async {
      final c = await loaded(categories: {'UCx': action});

      expect(
        [
          for (final g in c.read(historyCategoryGroupsProvider).groups)
            (g.path?.label ?? g.key, g.indices.length, g.channelCount),
        ],
        [('Gaming › Action game', 3, 1), (uncategorizedGroupKey, 1, 1)],
      );
    });

    test('the viewing mix counts only the kinds of videos shown', () async {
      final c = container(
        history: TakeoutHistory(
          watches: [
            _watch(
              'Song',
              DateTime(2026, 4, 12, 9),
              channelId: 'UCm',
            ).copyWith(music: true),
            _watch('Video', DateTime(2026, 4, 11, 9), channelId: 'UCx'),
          ],
        ),
        categories: {'UCm': const CategoryPath('Music'), 'UCx': action},
      );
      await c.read(takeoutHistoryProvider.future);
      await c.read(channelCategoriesProvider.future);
      List<(String, int)> mix() => [
        for (final s in c.read(viewingMixProvider))
          (s.pick.label, s.watchCount),
      ];

      expect(mix(), [('Gaming', 1), ('Music', 1)]);

      c.read(historyMusicFilterProvider.notifier).set(ShowFilter.only);
      expect(mix(), [('Music', 1), ('Gaming', 0)]);
    });
  });

  test('watched videos are grouped by month too', () async {
    final c = await loaded();

    final months = c.read(watchMonthsProvider);

    expect([for (final m in months) m.day], [DateTime(2026, 4)]);
    expect(months.single.indices, hasLength(4));
  });

  test(
    'the Removed filter keeps only entries no longer in YouTube history',
    () async {
      final removed = DateTime.utc(2026, 5);
      final c = container(
        history: TakeoutHistory(
          watches: [
            _watch('Kept', DateTime(2026, 4, 12, 9)),
            _watch(
              'Gone',
              DateTime(2026, 4, 11, 9),
            ).copyWith(removedAt: removed),
          ],
          searches: [
            SearchEntry(time: DateTime(2026, 4, 12).toUtc(), query: 'kept'),
            SearchEntry(
              time: DateTime(2026, 4, 11).toUtc(),
              query: 'gone',
              removedAt: removed,
            ),
          ],
        ),
      );
      final loaded = (await c.read(takeoutHistoryProvider.future))!.history;

      c.read(historyRemovedFilterProvider.notifier).set(true);
      await _settle(c);

      expect(
        [
          for (final day in c.read(watchDaysProvider))
            for (final i in day.indices) loaded.watches[i].title,
        ],
        ['Gone'],
      );
      expect(
        [
          for (final day in c.read(searchDaysProvider))
            for (final i in day.indices) loaded.searches[i].query,
        ],
        ['gone'],
      );

      c.read(historyRemovedFilterProvider.notifier).set(false);
      await _settle(c);
      expect(c.read(watchDaysProvider).expand((d) => d.indices), hasLength(2));
    },
  );

  test('no history means nothing to show', () async {
    final c = container(history: TakeoutHistory.empty);
    await c.read(takeoutHistoryProvider.future);

    expect(c.read(watchDaysProvider), isEmpty);
    expect(c.read(searchDaysProvider), isEmpty);
    expect(c.read(historyChannelGroupsProvider).groups, isEmpty);
  });
}
