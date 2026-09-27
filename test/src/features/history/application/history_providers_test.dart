import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/history/application/history_channel_filter.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_search_query.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_csv_codec.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_csv_encoder.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_repository.dart';
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

  final TakeoutHistory history;

  @override
  Future<TakeoutHistory?> build() async => history;
}

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

  ProviderContainer container({TakeoutHistory? history}) {
    final c = ProviderContainer(
      overrides: [
        takeoutRepositoryProvider.overrideWithValue(repository),
        if (history != null)
          takeoutHistoryProvider.overrideWith(() => _Fixed(history)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// A container showing [_history], loaded.
  Future<ProviderContainer> loaded() async {
    final c = container(history: _history);
    await c.read(takeoutHistoryProvider.future);
    return c;
  }

  List<String?> watchTitles(ProviderContainer c) => [
    for (final day in c.read(watchDaysProvider))
      for (final i in day.indices) _history.watches[i].title,
  ];

  group('loading', () {
    test("loads the selected takeout's history", () async {
      repository.accounts['UCme']!.addAll(encodeHistoryCsvs(_history));

      final history = await container().read(takeoutHistoryProvider.future);

      expect(history!.watches.map((w) => w.title), [
        'Café tour',
        'Other',
        'Unrelated',
        'Last',
      ]);
      expect(history.searches.map((s) => s.query), ['crème brûlée', 'cats']);
    });

    test('a takeout saved without history has none', () async {
      final history = await container().read(takeoutHistoryProvider.future);

      expect(history!.isEmpty, isTrue);
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

      expect(watchTitles(c), ['Café tour', 'Other']);
    },
  );

  test("the channel filter keeps only that channel's watches", () async {
    final c = await loaded();

    c
        .read(historyChannelFilterProvider.notifier)
        .show(const HistoryChannel(channelId: 'UCx', title: 'X'));

    expect(watchTitles(c), ['Café tour', 'Unrelated', 'Last']);
  });

  test(
    'the query and the channel filter narrow the watches together',
    () async {
      final c = await loaded();

      c
          .read(historyChannelFilterProvider.notifier)
          .show(const HistoryChannel(channelId: 'UCx', title: 'X'));
      c.read(historySearchQueryProvider.notifier).update('cafe');
      expect(watchTitles(c), ['Café tour']);

      c.read(historyChannelFilterProvider.notifier).clear();
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

    expect(queries(), ['crème brûlée']);
  });

  test(
    'top channels are ordered by watch count and filtered by the query',
    () async {
      final c = await loaded();
      List<(String, int)> channels() => [
        for (final c in c.read(filteredWatchedChannelsProvider))
          (c.channel.title, c.count),
      ];

      expect(channels(), [('X', 3), ('CAFE Channel', 1)]);
      c.read(historySearchQueryProvider.notifier).update('café');

      expect(channels(), [('CAFE Channel', 1)]);
    },
  );

  test('no history means nothing to show', () async {
    final c = container(history: TakeoutHistory.empty);
    await c.read(takeoutHistoryProvider.future);

    expect(c.read(watchDaysProvider), isEmpty);
    expect(c.read(searchDaysProvider), isEmpty);
    expect(c.read(filteredWatchedChannelsProvider), isEmpty);
  });
}
