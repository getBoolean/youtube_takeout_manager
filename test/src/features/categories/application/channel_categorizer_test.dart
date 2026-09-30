import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_tiers.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/categorization_progress.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
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
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
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

/// Jev, agreeing with every category YouTube gives [agree] sure, or failing
/// with [failure] from its [failAfter]th request on.
class _Jev extends TypeSafeRepository {
  _Jev({this.agree = 0.9, this.failure, this.failAfter = 0});

  final double agree;
  final AiFailure? failure;
  final int failAfter;
  var requests = 0;

  @override
  Future<Map<String, JevAnswer>> ask({
    required String apiKey,
    required Object state,
    required Map<String, JevQuestion> questions,
  }) async {
    if (failure case final f? when requests++ >= failAfter) throw f;
    return {
      for (final MapEntry(:key, :value) in questions.entries)
        key: switch (value) {
          JevNoul() => NoulAnswer(agree),
          JevChoice(:final options) => ChoiceAnswer(
            choice: options.keys.first,
            probabilities: {options.keys.first: 0.1},
            confidence: 0.1,
          ),
        },
    };
  }
}

/// Claude, answering with [answer], keeping what it was asked.
class _Claude extends AnthropicRepository {
  _Claude(this.answer);

  final Map<String, Object?> answer;
  final asked = <String>[];

  @override
  Future<Map<String, Object?>> structured({
    required String apiKey,
    required String model,
    required String system,
    required String user,
    required Map<String, Object?> schema,
  }) async {
    asked.add(user);
    return answer;
  }
}

/// The AI keys, changeable as when entered in the app.
class _Keys extends Notifier<AiKeys> {
  @override
  AiKeys build() => AiKeys.none;

  void set(AiKeys keys) => state = keys;
}

final _keys = NotifierProvider<_Keys, AiKeys>(_Keys.new);

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
    AiKeys keys = AiKeys.none,
    TypeSafeRepository? jev,
    AnthropicRepository? claude,
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
        aiKeysProvider.overrideWith((ref) async => ref.watch(_keys)),
        typeSafeRepositoryProvider.overrideWithValue(jev ?? _Jev()),
        anthropicRepositoryProvider.overrideWithValue(
          claude ??
              _Claude({'parent': 'Knowledge', 'child': null, 'reason': ''}),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.read(_keys.notifier).set(keys);
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

  group('with a Jev key', () {
    const jevKey = AiKeys(typesafe: 'jv_live_1');

    test("Jev checks the categories YouTube gives", () async {
      final c = container(details: known, keys: jevKey, jev: _Jev());

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      final gamer = c.read(channelCategoriesProvider).value?['UCg'];
      expect(gamer?.path, const CategoryPath('Gaming', 'Action'));
      expect(gamer?.jevAgreed, 0.9);
      expect(gamer?.tried, contains(CategorizationTier.jev));
    });

    test("a rejected key turns Jev off, saying so once, and YouTube's "
        'categories still come', () async {
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(failure: const AiKeyRejected()),
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      final status = c.read(aiTierStatusProvider);
      expect(status.disabled, {AiService.jev});
      expect(status.notice, isNotNull);
      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      expect(
        c.read(channelCategoriesProvider).value?['UCg']?.jevAgreed,
        isNull,
      );
    });

    test(
      'adding the key later has Jev check the categories already made',
      () async {
        final c = container(details: known, jev: _Jev(agree: 0.8));
        c.read(historyShownProvider.notifier).markShown();
        await _settle();
        expect(
          c.read(channelCategoriesProvider).value?['UCg']?.jevAgreed,
          isNull,
        );

        c.read(_keys.notifier).set(jevKey);
        await _settle();

        expect(c.read(channelCategoriesProvider).value?['UCg']?.jevAgreed, 0.8);
      },
    );

    test('when Jev is busy, categorizing stops for now, keeping what it '
        'made, and says so', () async {
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(failure: const AiOverloaded(), failAfter: 1),
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      final status = c.read(aiTierStatusProvider);
      expect(status.disabled, isEmpty);
      expect(status.notice, isNotNull);
      expect(
        c
            .read(channelCategoriesProvider)
            .value!
            .values
            .where((category) => category.jevAgreed != null),
        hasLength(1),
      );
    });
  });

  group('with a Claude key', () {
    const claudeKey = AiKeys(anthropic: 'sk-ant-1');

    test('Claude names the categories YouTube gives none for, and a new '
        'sub-category it names is kept', () async {
      final claude = _Claude({
        'parent': 'Gaming',
        'child': 'Speedruns',
        'reason': 'Races through games',
      });
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      // No Unknown topics for No topics, so Claude named it.
      final none = c.read(channelCategoriesProvider).value?['UCx'];
      expect(none?.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(none?.source, CategorySource.claude);
      expect(none?.reason, 'Races through games');
      // YouTube's sub-categories stand.
      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      expect(await c.read(customCategoriesProvider.future), {
        'Gaming': ['Speedruns'],
      });
    });

    test('asked again, Claude suggests another category, and accepting it '
        'keeps it as the user chose', () async {
      final claude = _Claude({
        'parent': 'Gaming',
        'child': 'Speedruns',
        'reason': 'Races, not fights',
      });
      final c = container(details: known, keys: claudeKey, claude: claude);
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      final categorizer = c.read(channelCategorizerProvider.notifier);
      const gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');
      expect(categorizer.canAskAi, isTrue);

      final suggestion = await categorizer.suggest(gamer);
      expect(suggestion.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(claude.asked.last, contains('Gaming › Action'));
      await categorizer.accept(gamer, suggestion);

      final kept = c.read(channelCategoriesProvider).value?['UCg'];
      expect(kept?.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(kept?.userDecision, UserDecision.accepted);
      expect(await c.read(customCategoriesProvider.future), contains('Gaming'));
    });

    test("denying a suggestion keeps the category, and it's not asked "
        'about again', () async {
      final c = container(
        details: known,
        keys: claudeKey,
        claude: _Claude({'parent': 'Music', 'child': null, 'reason': ''}),
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      final categorizer = c.read(channelCategorizerProvider.notifier);
      const gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');

      await categorizer.deny(gamer);
      c.read(_keys.notifier).set(const AiKeys(anthropic: 'sk-ant-2'));
      await _settle();

      final kept = c.read(channelCategoriesProvider).value?['UCg'];
      expect(kept?.path, const CategoryPath('Gaming', 'Action'));
      expect(kept?.userDecision, UserDecision.denied);
    });
  });

  test('without any key, AI cannot be asked', () async {
    final c = container(details: known);
    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(c.read(channelCategorizerProvider.notifier).canAskAi, isFalse);
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
