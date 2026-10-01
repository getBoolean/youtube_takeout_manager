import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_tiers.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/categorization_progress.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_pause_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/model_capabilities_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/model_capabilities.dart';
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
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

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

  /// As switching to another takeout does.
  void switchTo(TakeoutHistory other) =>
      state = AsyncData(LoadedHistory.of(other));
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
/// with [failure], an AI failure or not, from its [failAfter]th request on.
class _Jev extends TypeSafeRepository {
  _Jev({this.agree = 0.9, this.failure, this.failAfter = 0});

  final double agree;
  Object? failure;
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

/// Claude, answering with [answer] once [hold] completes, or failing with
/// [failure], keeping what it was asked. Its model answers in shapes when
/// [structuredOutputs].
class _Claude extends AnthropicRepository {
  _Claude(
    this.answer, {
    this.failure,
    this.hold,
    this.structuredOutputs = true,
  });

  final Map<String, Object?> answer;
  final AiFailure? failure;
  final Completer<void>? hold;
  final bool structuredOutputs;
  final asked = <String>[];

  /// The models whose capabilities were asked for.
  final capabilitiesAsked = <String>[];

  @override
  Future<ModelCapabilities> capabilities({
    required String apiKey,
    required String model,
  }) async {
    capabilitiesAsked.add(model);
    return ModelCapabilities(
      id: model,
      structuredOutputs: structuredOutputs,
      lowEffort: false,
    );
  }

  @override
  Future<Map<String, Object?>> structured({
    required String apiKey,
    required ModelCapabilities model,
    required String system,
    required String user,
    required Map<String, Object?> schema,
  }) async {
    asked.add(user);
    await hold?.future;
    if (failure case final failure?) throw failure;
    return answer;
  }
}

/// Timers made, to fire by hand.
class _Timers {
  final made = <({Duration after, void Function() fire, _Timer timer})>[];

  Timer call(Duration after, void Function() fire) {
    final timer = _Timer();
    made.add((after: after, fire: fire, timer: timer));
    return timer;
  }

  /// The timers not cancelled, by when they fire.
  Iterable<({Duration after, void Function() fire, _Timer timer})> get active =>
      made.where((t) => t.timer.isActive);
}

class _Timer implements Timer {
  @override
  bool isActive = true;

  @override
  void cancel() => isActive = false;

  @override
  int get tick => 0;
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
    TakeoutHistory? history,
    bool browser = false,
    _Timers? timers,
    DateTime Function()? now,
  }) {
    fetcher = _Fetcher(give);
    final c = ProviderContainer(
      overrides: [
        takeoutHistoryProvider.overrideWith(() => _Fixed(history ?? _history)),
        channelCategorizerProvider.overrideWith(
          () => ChannelCategorizer(
            browser: browser,
            timer: timers?.call ?? Timer.new,
            now: now ?? DateTime.now,
          ),
        ),
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
      // No topics, and no AI to ask.
      'UCx': null,
    });
    expect(
      c.read(channelCategoriesProvider).value?['UCg']?.source,
      CategorySource.youtube,
    );
  });

  test('without topics or AI, a channel is uncategorized, and not counted '
      'as categorized', () async {
    final c = container(details: known);
    final seen = <({bool running, int done, int total})>[];
    c.listen(categorizationProgressProvider, (_, p) => seen.add(p));

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(paths(c), containsPair('UCx', null));
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

    test('a request Jev turns down turns it off for now, saying so, and '
        "YouTube's categories still come", () async {
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(failure: const AiBadRequest('Too many options')),
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      final status = c.read(aiTierStatusProvider);
      expect(status.disabled, {AiService.jev});
      expect(status.notice, isNotNull);
      expect(paths(c)['UCs'], const CategoryPath('Music', 'Pop'));
    });

    test("in a browser, Jev that can't be reached is turned off at once, "
        'and categorizing finishes without it', () async {
      final jev = _Jev(failure: const AiUnreachable());
      final c = container(
        details: known,
        keys: jevKey,
        jev: jev,
        browser: true,
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      expect(c.read(aiTierStatusProvider).disabled, {AiService.jev});
      // Only the channels already asked about when it failed, three at once.
      expect(jev.requests, lessThanOrEqualTo(3));
      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      expect(paths(c)['UCs'], const CategoryPath('Music', 'Pop'));
    });

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

    test('when Jev is busy, categorizing pauses, keeping what it made, and '
        'says so', () async {
      final timers = _Timers();
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(failure: const AiOverloaded(), failAfter: 1),
        timers: timers,
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      final status = c.read(aiTierStatusProvider);
      expect(status.disabled, isEmpty);
      expect(status.notice, isNotNull);
      expect(timers.active, hasLength(1));
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

    test("the model's capabilities are asked for once, and kept after a "
        'restart', () async {
      final claude = _Claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      });
      final first = container(details: known, keys: claudeKey, claude: claude);
      first.read(historyShownProvider.notifier).markShown();
      await _settle();
      expect(claude.capabilitiesAsked, [anthropicModel]);
      first.dispose();

      final again = container(
        details: known,
        keys: claudeKey,
        claude: claude,
        history: TakeoutHistory(watches: [_watch('UCq', 'Quiet')]),
      );
      again.read(historyShownProvider.notifier).markShown();
      await _settle();

      expect(claude.asked, isNotEmpty);
      expect(claude.capabilitiesAsked, [anthropicModel]);
    });

    test('capabilities kept for another model are asked for again', () async {
      await ModelCapabilitiesRepository(KvStorageService()).save(
        const ModelCapabilities(
          id: 'claude-some-other-model',
          structuredOutputs: true,
          lowEffort: true,
        ),
      );
      final claude = _Claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      });
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      expect(claude.capabilitiesAsked, [anthropicModel]);
    });

    test("a model that can't answer in shapes turns Claude off, saying so, "
        "and YouTube's and Jev's categories still come", () async {
      final claude = _Claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      }, structuredOutputs: false);
      final c = container(
        details: known,
        keys: const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-1'),
        jev: _Jev(),
        claude: claude,
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      final status = c.read(aiTierStatusProvider);
      expect(status.disabled, {AiService.claude});
      expect(status.notice, isNotNull);
      expect(claude.asked, isEmpty);
      final gamer = c.read(channelCategoriesProvider).value?['UCg'];
      expect(gamer?.path, const CategoryPath('Gaming', 'Action'));
      expect(gamer?.jevAgreed, 0.9);
    });

    test('a channel Claude gives no usable answer for is left as it was, the '
        "rest go on, and it isn't paid for again", () async {
      final claude = _Claude(const {}, failure: const AiNoAnswer());
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      expect(paths(c), containsPair('UCx', null));
      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      expect(c.read(aiTierStatusProvider).disabled, isEmpty);

      // A new key has every channel looked at again.
      c.read(_keys.notifier).set(const AiKeys(anthropic: 'sk-ant-2'));
      await _settle();
      expect(claude.asked, hasLength(1));
    });

    test('a decision the user makes while AI is asked is kept', () async {
      final hold = Completer<void>();
      final claude = _Claude({
        'parent': 'Gaming',
        'child': null,
        'reason': '',
      }, hold: hold);
      final c = container(details: known, keys: claudeKey, claude: claude);
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      expect(claude.asked, hasLength(1));

      const topicless = HistoryChannel(channelId: 'UCx', title: 'No topics');
      await c.read(channelCategorizerProvider.notifier).deny(topicless);
      hold.complete();
      await _settle();

      final kept = c.read(channelCategoriesProvider).value?['UCx'];
      expect(kept?.userDecision, UserDecision.denied);
      expect(kept?.path, isNull);
    });

    test('switching takeouts stops the run under way, keeping the answers '
        'already asked for', () async {
      final hold = Completer<void>();
      final claude = _Claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      }, hold: hold);
      // No topics for any: each goes to Claude, three at a time.
      final c = container(
        keys: claudeKey,
        claude: claude,
        history: TakeoutHistory(
          watches: [
            for (final id in ['UC1', 'UC2', 'UC3', 'UC4'])
              _watch(id, 'Channel $id'),
          ],
        ),
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      expect(claude.asked, hasLength(3));

      (c.read(takeoutHistoryProvider.notifier) as _Fixed).switchTo(
        TakeoutHistory(watches: [_watch('UCo', 'Other')]),
      );
      await _settle();
      hold.complete();
      await _settle();

      expect(paths(c).keys, containsAll(['UC1', 'UC2', 'UC3', 'UCo']));
      expect(paths(c).containsKey('UC4'), isFalse);
      expect(claude.asked, hasLength(4));
    });

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

  group('when a service asks to wait', () {
    const jevKey = AiKeys(typesafe: 'jv_live_1');
    final t0 = DateTime.utc(2026, 10, 1, 12);

    AiPauseRepository pauses() => AiPauseRepository(KvStorageService());

    int agreed(ProviderContainer c) => c
        .read(channelCategoriesProvider)
        .value!
        .values
        .where((category) => category.jevAgreed != null)
        .length;

    test('busy without saying how long, categorizing pauses, says so, keeps '
        'the pause, and resumes itself after 5 minutes', () async {
      final timers = _Timers();
      final jev = _Jev(failure: const AiOverloaded());
      final c = container(
        details: known,
        keys: jevKey,
        jev: jev,
        timers: timers,
        now: () => t0,
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      expect(c.read(aiTierStatusProvider).disabled, isEmpty);
      expect(c.read(aiTierStatusProvider).notice, isNotNull);
      expect(timers.active.single.after, const Duration(minutes: 5));
      expect(await pauses().load(now: t0), {
        AiService.jev: t0.add(const Duration(minutes: 5)),
      });
      expect(agreed(c), 0);

      jev.failure = null;
      timers.active.single.fire();
      await _settle();

      expect(agreed(c), 2);
      expect(c.read(aiTierStatusProvider).notice, isNull);
      expect(await pauses().load(now: t0), isEmpty);
    });

    test('rate-limited until a stated time, it resumes then', () async {
      final timers = _Timers();
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(
          failure: AiRateLimited(
            'Too many requests for now.',
            t0.add(const Duration(seconds: 90)),
          ),
        ),
        timers: timers,
        now: () => t0,
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      expect(timers.active.single.after, const Duration(seconds: 90));
    });

    test('runs asked for while paused wait for the resume', () async {
      final timers = _Timers();
      final jev = _Jev(failure: const AiOverloaded());
      final c = container(
        details: known,
        keys: jevKey,
        jev: jev,
        timers: timers,
        now: () => t0,
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      jev.failure = null;
      double? singerAgreed() =>
          c.read(channelCategoriesProvider).value?['UCs']?.jevAgreed;

      (c.read(takeoutHistoryProvider.notifier) as _Fixed).switchTo(
        TakeoutHistory(watches: [_watch('UCs', 'Singer')]),
      );
      await _settle();
      expect(singerAgreed(), isNull);

      timers.active.single.fire();
      await _settle();
      expect(singerAgreed(), 0.9);
    });

    test('a new key ends the pause, and categorizing runs at once', () async {
      final timers = _Timers();
      final jev = _Jev(failure: const AiOverloaded());
      final c = container(
        details: known,
        keys: jevKey,
        jev: jev,
        timers: timers,
        now: () => t0,
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      jev.failure = null;

      c.read(_keys.notifier).set(const AiKeys(typesafe: 'jv_live_2'));
      await _settle();

      expect(timers.active, isEmpty);
      expect(agreed(c), 2);
      expect(await pauses().load(now: t0), isEmpty);
    });

    test('a pause kept from before a restart still holds for the time left, '
        'then categorizing resumes', () async {
      await pauses().save(
        AiService.jev,
        t0.add(const Duration(minutes: 5)),
        since: t0,
      );
      final timers = _Timers();
      final jev = _Jev();
      final c = container(
        details: known,
        keys: jevKey,
        jev: jev,
        timers: timers,
        now: () => t0.add(const Duration(minutes: 2)),
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      expect(jev.requests, 0);
      expect(timers.active.single.after, const Duration(minutes: 3));

      timers.active.single.fire();
      await _settle();
      expect(agreed(c), 2);
    });

    test('a pause kept from before a restart that has passed waits for '
        'nothing, and is forgotten', () async {
      await pauses().save(
        AiService.jev,
        t0.subtract(const Duration(minutes: 1)),
        since: t0.subtract(const Duration(minutes: 6)),
      );
      final timers = _Timers();
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(),
        timers: timers,
        now: () => t0,
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      expect(timers.active, isEmpty);
      expect(agreed(c), 2);
      expect(await pauses().load(now: t0), isEmpty);
    });

    test('asking AI during a kept pause fails at once, saying when it '
        'resumes', () async {
      final resumeAt = t0.add(const Duration(minutes: 5));
      await pauses().save(AiService.claude, resumeAt, since: t0);
      var messages = 0;
      final claude = AnthropicRepository(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'capabilities': {
                  'structured_outputs': {'supported': true},
                },
              }),
              200,
            );
          }
          messages++;
          return http.Response('{}', 500);
        }),
        browser: false,
        now: () => t0.add(const Duration(minutes: 2)),
        sleep: (_) async {},
      );
      final c = container(
        details: known,
        keys: const AiKeys(anthropic: 'sk-ant-1'),
        claude: claude,
        timers: _Timers(),
        now: () => t0.add(const Duration(minutes: 2)),
      );
      await _settle();

      final failure = await c
          .read(channelCategorizerProvider.notifier)
          .suggest(const HistoryChannel(channelId: 'UCg', title: 'Gamer'))
          .then<Object>((_) => 'no failure', onError: (Object e) => e);

      expect(
        failure,
        isA<AiTierFailure>().having(
          (f) => f.failure,
          'failure',
          isA<AiRateLimited>().having((f) => f.resumeAt, 'resumeAt', resumeAt),
        ),
      );
      expect(messages, 0);
    });

    test('closing the app stops the timer', () async {
      final timers = _Timers();
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(failure: const AiOverloaded()),
        timers: timers,
        now: () => t0,
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      expect(timers.active, hasLength(1));

      c.dispose();

      expect(timers.active, isEmpty);
    });
  });

  group('what an AI failure does', () {
    const jevKey = AiKeys(typesafe: 'jv_live_1');

    test('a billing problem turns the service off, quoting the API', () async {
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(failure: const AiBillingProblem('Top up at the console.')),
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      final status = c.read(aiTierStatusProvider);
      expect(status.disabled, {AiService.jev});
      expect(status.notice, contains('Top up at the console.'));
    });

    test(
      'an unexpected failure turns the service off, saying what it was',
      () async {
        final c = container(
          details: known,
          keys: jevKey,
          jev: _Jev(failure: const AiUnexpected('the answer had no answers')),
        );

        c.read(historyShownProvider.notifier).markShown();
        await _settle();

        final status = c.read(aiTierStatusProvider);
        expect(status.disabled, {AiService.jev});
        expect(status.notice, contains('the answer had no answers'));
      },
    );

    test('an error that is no AI failure stops the run, saying so, and is '
        'never thrown', () async {
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(failure: StateError('kaput')),
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      expect(c.read(aiTierStatusProvider).notice, isNotNull);
      expect(c.read(categorizationProgressProvider).running, isFalse);
    });
  });
}
