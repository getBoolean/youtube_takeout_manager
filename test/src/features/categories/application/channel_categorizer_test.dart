import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/categorization_progress.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel_details.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_shown.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';

String _topic(String slug) => 'https://en.wikipedia.org/wiki/$slug';

WatchEntry _watch(String channelId, String channel) => WatchEntry(
  time: DateTime.utc(2026, 4, 12),
  kind: WatchKind.video,
  title: 'A video by $channel',
  url: 'https://www.youtube.com/watch?v=${channelId.hashCode}',
  channelTitle: channel,
  channelUrl: 'https://www.youtube.com/channel/$channelId',
);

class _Fixed extends TakeoutHistoryNotifier {
  _Fixed(this.history);

  final TakeoutHistory history;

  @override
  Future<LoadedHistory?> build() async => LoadedHistory.of(history);
}

class _Details extends ChannelDetailsNotifier {
  _Details(this.details);

  final Map<String, ChannelDetails> details;

  @override
  Future<Map<String, ChannelDetails>> build() async => details;
}

/// Records the channels details are asked for, and gives them topics.
class _Fetcher extends ChannelThumbnailFetcher {
  _Fetcher(this.give);

  final Map<String, ChannelDetails> give;
  final asked = <List<String>>[];

  @override
  void build() {}

  @override
  Future<void> fetchDetails(Iterable<String> channelIds) async {
    asked.add(channelIds.toList());
    await ref.read(channelDetailsProvider.notifier).add({
      for (final id in channelIds) id: ?give[id],
    });
  }
}

Future<void> _settle() async {
  for (var i = 0; i < 30; i++) {
    await pumpEventQueue();
  }
}

// Gamer is watched most, then Singer; Newsy is only subscribed to.
final _history = TakeoutHistory(
  watches: [
    _watch('UCg', 'Gamer'),
    _watch('UCs', 'Singer'),
    _watch('UCg', 'Gamer'),
    _watch('UCx', 'No topics'),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late _Fetcher fetcher;

  ProviderContainer container({
    Map<String, ChannelDetails> details = const {},
    Map<String, ChannelDetails> give = const {},
    String? session,
    List<Subscription> subscriptions = const [],
  }) {
    fetcher = _Fetcher(give);
    final c = ProviderContainer(
      overrides: [
        takeoutHistoryProvider.overrideWith(() => _Fixed(_history)),
        channelDetailsProvider.overrideWith(() => _Details({...details})),
        channelThumbnailFetcherProvider.overrideWith(() => fetcher),
        readSessionChannelIdProvider.overrideWithValue(session),
        historySubscriptionsProvider.overrideWith(
          (ref) async => {for (final s in subscriptions) s.channelId: s},
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(channelCategorizerProvider, (_, _) {});
    return c;
  }

  final known = {
    'UCg': ChannelDetails(
      topicUrls: [_topic('Video_game_culture'), _topic('Action_game')],
    ),
    'UCs': ChannelDetails(topicUrls: [_topic('Pop_music')]),
    'UCn': ChannelDetails(topicUrls: [_topic('Politics')]),
    'UCx': const ChannelDetails(),
  };

  Map<String, CategoryPath?> paths(ProviderContainer c) => {
    for (final MapEntry(:key, :value)
        in (c.read(channelCategoriesProvider).value ?? const {}).entries)
      key: value.path,
  };

  test('nothing is categorized before the history is shown', () async {
    final c = container(details: known);
    await _settle();

    expect(paths(c), isEmpty);
  });

  test("YouTube's topics give channels their categories, subscriptions "
      'never watched too', () async {
    final c = container(
      details: known,
      subscriptions: [
        const Subscription(
          channelId: 'UCn',
          channelUrl: 'http://www.youtube.com/channel/UCn',
          channelTitle: 'Newsy',
        ),
      ],
    );

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(paths(c), {
      'UCg': const CategoryPath('Gaming', 'Action'),
      'UCs': const CategoryPath('Music', 'Pop'),
      'UCn': const CategoryPath('Society', 'Politics'),
    });
    expect(
      c.read(channelCategoriesProvider).value?['UCg']?.source,
      CategorySource.youtube,
    );
  });

  test('without topics or AI, a channel is left uncategorized and not '
      'counted', () async {
    final c = container(details: known);
    final seen = <({bool running, int done, int total})>[];
    c.listen(categorizationProgressProvider, (_, p) => seen.add(p));

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(paths(c).containsKey('UCx'), isFalse);
    expect(seen.map((p) => p.total), everyElement(2));
    expect(seen.last.running, isFalse);
  });

  test('signed in, channels whose topics are unknown are asked for first, '
      'the most watched first', () async {
    final c = container(session: 'UCme', give: known);

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    // Gamer is watched most; the rest, as often, by name.
    expect(fetcher.asked.first, ['UCg', 'UCx', 'UCs']);
    expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
  });

  test('a category the user accepted or denied is never replaced', () async {
    final c = container(details: known);
    await c.read(channelCategoriesProvider.future);
    await c
        .read(channelCategoriesProvider.notifier)
        .decide(
          'UCg',
          ChannelCategory(
            path: const CategoryPath('Gaming', 'Speedruns'),
            source: CategorySource.claude,
            userDecision: UserDecision.accepted,
            decidedAt: DateTime.utc(2026, 9, 30),
          ),
        );

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Speedruns'));
  });

  test('categories are kept after a restart, and not made again', () async {
    final first = container(details: known);
    first.read(historyShownProvider.notifier).markShown();
    await _settle();
    first.dispose();

    final again = container(details: const {});
    await again.read(channelCategoriesProvider.future);

    expect(paths(again)['UCg'], const CategoryPath('Gaming', 'Action'));
  });
}
