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
import 'package:youtube_takeout_manager/src/features/categories/application/ai_results_clearer.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_tiers.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/categorization_progress.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/categorizing_channels.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/category_editor.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/prompt_fingerprints.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/tag_editor.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_pause_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/model_capabilities_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';
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
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_details_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

import '../ai_fakes.dart';

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
/// Of options, it picks the first, unsure, or one described as starting
/// with [prefer], sure. Keeps the questions asked.
class _Jev extends TypeSafeRepository {
  _Jev({
    this.agree = 0.9,
    this.failure,
    this.failAfter = 0,
    this.prefer,
    this.tagFits = const {},
  });

  final double agree;

  /// How likely yes is for each tag it's asked about, by name; no for the
  /// rest, and for something no tag names.
  final Map<String, double> tagFits;
  Object? failure;
  final int failAfter;
  final String? prefer;
  var requests = 0;
  final asked = <JevQuestion>[];

  @override
  Future<Map<String, JevAnswer>> ask({
    required String apiKey,
    required Object state,
    required Map<String, JevQuestion> questions,
  }) async {
    if (failure case final f? when requests++ >= failAfter) throw f;
    asked.addAll(questions.values);
    return {
      for (final MapEntry(:key, :value) in questions.entries)
        key: switch (value) {
          JevNoul() when key == 'other' => const NoulAnswer(0),
          JevNoul(:final instructions) when key.startsWith('tag_') =>
            NoulAnswer(
              tagFits.entries
                      .where((f) => instructions.contains('"${f.key}"'))
                      .firstOrNull
                      ?.value ??
                  0,
            ),
          JevNoul() => NoulAnswer(agree),
          JevChoice(:final options) => _pick(options),
        },
    };
  }

  ChoiceAnswer _pick(Map<String, String?> options) {
    final preferred = options.entries
        .where((o) => prefer != null && (o.value?.startsWith(prefer!) ?? false))
        .firstOrNull;
    final choice = preferred?.key ?? options.keys.first;
    final odds = preferred == null ? 0.1 : 0.9;
    return ChoiceAnswer(
      choice: choice,
      probabilities: {choice: odds},
      confidence: odds,
    );
  }
}

/// Claude, answering with [answer] once [hold] completes, or failing with
/// [failure], keeping what it was asked. Its model answers in shapes when
/// [structuredOutputs].
ScriptedClaude _claude(
  Map<String, Object?> answer, {
  List<Object?> tags = const [],
  AiFailure? failure,
  Completer<void>? hold,
  bool structuredOutputs = true,
  AiFailure? capabilitiesFailure,
}) => ScriptedClaude(
  category: answer,
  tags: tags,
  failure: failure,
  hold: hold,
  structuredOutputs: structuredOutputs,
  capabilitiesFailure: capabilitiesFailure,
);

/// Fetches nothing: gives each video asked for a description, as YouTube
/// would, and records the IDs.
class _VideoDetails extends VideoDetailsFetcher {
  _VideoDetails({this.endless = false});

  /// Whether it fetches until told to stop, as thousands of videos would.
  final bool endless;
  final asked = <String>{};

  @override
  Future<void> fetch(Iterable<String> videoIds, {bool Function()? stop}) async {
    while (endless && !(stop?.call() ?? false)) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    asked.addAll(videoIds);
    ref.read(videoMetadataProvider.notifier).addAll([
      for (final id in videoIds)
        Video(videoId: id, channelId: 'UCx', description: 'Fetched about $id'),
    ]);
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

/// Clicks Run, as the Categorize window does, and lets the run go.
Future<void> _runAi(ProviderContainer c) async {
  c.read(channelCategorizerProvider.notifier).run();
  await _settle();
}

/// The subscriptions, changeable as when a takeout's arrive.
class _Subs extends Notifier<List<Subscription>> {
  @override
  List<Subscription> build() => const [];

  void set(List<Subscription> subscriptions) => state = subscriptions;
}

final _subs = NotifierProvider<_Subs, List<Subscription>>(_Subs.new);

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
    _VideoDetails? videoDetails,
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
        videoDetailsFetcherProvider.overrideWith(
          () => videoDetails ?? _VideoDetails(),
        ),
        readSessionChannelIdProvider.overrideWithValue(session),
        historySubscriptionsProvider.overrideWith(
          (ref) async => {for (final s in ref.watch(_subs)) s.channelId: s},
        ),
        aiKeysProvider.overrideWith((ref) async => ref.watch(_keys)),
        typeSafeRepositoryProvider.overrideWithValue(jev ?? _Jev()),
        anthropicRepositoryProvider.overrideWithValue(
          claude ??
              _claude({'parent': 'Knowledge', 'child': null, 'reason': ''}),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.read(_keys.notifier).set(keys);
    c.read(_subs.notifier).set(subscriptions);
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
    final seen = <RunProgress>[];
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
      await _runAi(c);

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
      await _runAi(c);

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
      await _runAi(c);

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
      await _runAi(c);

      final status = c.read(aiTierStatusProvider);
      expect(status.disabled, {AiService.jev});
      expect(status.notice, isNotNull);
      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      expect(
        c.read(channelCategoriesProvider).value?['UCg']?.jevAgreed,
        isNull,
      );
    });

    test('adding the key later starts nothing, and Run then has Jev check the '
        'categories already made', () async {
      final jev = _Jev(agree: 0.8);
      final c = container(details: known, jev: jev);
      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      c.read(_keys.notifier).set(jevKey);
      await _settle();
      expect(jev.requests, 0);
      expect(
        c.read(channelCategoriesProvider).value?['UCg']?.jevAgreed,
        isNull,
      );

      await _runAi(c);
      expect(c.read(channelCategoriesProvider).value?['UCg']?.jevAgreed, 0.8);
    });

    test('Jev is offered the sub-categories channels have most, when there '
        'are more than it takes', () async {
      final jev = _Jev(prefer: 'Knowledge');
      final c = container(details: known, keys: jevKey, jev: jev);
      final custom = c.read(customCategoriesProvider.notifier);
      for (var i = 1; i <= 300; i++) {
        await custom.add('Knowledge', 'Topic $i');
      }
      await c.read(channelCategoriesProvider.future);
      await c
          .read(channelCategoriesProvider.notifier)
          .decide(
            'UCq',
            ChannelCategory(
              path: const CategoryPath('Knowledge', 'Topic 300'),
              userDecision: UserDecision.accepted,
              decidedAt: DateTime.utc(2026, 9, 30),
            ),
          );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      final knowledge = jev.asked.whereType<JevChoice>().where(
        (question) => question.options.values.contains('Topic 1'),
      );
      expect(knowledge, isNotEmpty);
      for (final question in knowledge) {
        expect(
          question.options.length,
          lessThanOrEqualTo(JevChoice.maxOptions),
        );
        expect(question.options.values, contains('Topic 300'));
      }
    });

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
      await _runAi(c);

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
      final claude = _claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      });
      final first = container(details: known, keys: claudeKey, claude: claude);
      first.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(first);
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
      await _runAi(again);

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
      final claude = _claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      });
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      expect(claude.capabilitiesAsked, [anthropicModel]);
    });

    test("when Claude's model can't be looked up, categorizing goes on "
        'without Claude, saying so', () async {
      final claude = _claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      }, capabilitiesFailure: const AiUnreachable());
      final c = container(
        details: known,
        keys: const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-1'),
        jev: _Jev(),
        claude: claude,
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      final status = c.read(aiTierStatusProvider);
      expect(status.disabled, isEmpty);
      expect(status.notice, isNotNull);
      expect(claude.asked, isEmpty);
      final gamer = c.read(channelCategoriesProvider).value?['UCg'];
      expect(gamer?.path, const CategoryPath('Gaming', 'Action'));
      expect(gamer?.jevAgreed, 0.9);
    });

    test("a model that can't answer in shapes turns Claude off, saying so, "
        "and YouTube's and Jev's categories still come", () async {
      final claude = _claude({
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
      await _runAi(c);

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
      final claude = _claude(const {}, failure: const AiNoAnswer());
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      expect(paths(c), containsPair('UCx', null));
      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      expect(c.read(aiTierStatusProvider).disabled, isEmpty);
      final asked = claude.asked.length;

      // A new key has every channel looked at again.
      c.read(_keys.notifier).set(const AiKeys(anthropic: 'sk-ant-2'));
      await _settle();
      expect(claude.asked, hasLength(asked));
    });

    test('a decision the user makes while AI is asked is kept', () async {
      final hold = Completer<void>();
      final claude = _claude({
        'parent': 'Gaming',
        'child': null,
        'reason': '',
      }, hold: hold);
      final c = container(details: known, keys: claudeKey, claude: claude);
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      expect(claude.asked, isNotEmpty);

      const topicless = HistoryChannel(channelId: 'UCx', title: 'No topics');
      await c.read(categoryEditorProvider.notifier).deny(topicless);
      hold.complete();
      await _settle();

      final kept = c.read(channelCategoriesProvider).value?['UCx'];
      expect(kept?.userDecision, UserDecision.denied);
      expect(kept?.path, isNull);
    });

    test('switching takeouts stops the run under way, keeping the answers '
        "already asked for; the other takeout gets YouTube's categories "
        'alone', () async {
      final hold = Completer<void>();
      final claude = _claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      }, hold: hold);
      // No topics for any: all go to Claude, in one request.
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
      await c.read(takeoutSelectionProvider.notifier).select('first');
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      expect(claude.kinds, hasLength(4));

      await c.read(takeoutSelectionProvider.notifier).select('other');
      (c.read(takeoutHistoryProvider.notifier) as _Fixed).switchTo(
        TakeoutHistory(watches: [_watch('UCo', 'Other')]),
      );
      await _settle();
      hold.complete();
      await _settle();

      expect([
        for (final id in ['UC1', 'UC2', 'UC3', 'UC4']) paths(c)[id],
      ], List.filled(4, const CategoryPath('Knowledge')));
      expect(paths(c).containsKey('UCo'), isTrue);
      expect(paths(c)['UCo'], isNull);
      expect(claude.kinds, hasLength(4));
    });

    test('Claude names the categories YouTube gives none for, and a new '
        'sub-category it names is kept', () async {
      final claude = _claude({
        'parent': 'Gaming',
        'child': 'Speedruns',
        'reason': 'Races through games',
      });
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      // No Unknown topics for No topics, so Claude named it.
      final none = c.read(channelCategoriesProvider).value?['UCx'];
      expect(none?.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(none?.source, CategorySource.claude);
      expect(none?.reason, 'Races through games');
      // YouTube's sub-categories stand.
      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      expect(subCategoryNames(await c.read(customCategoriesProvider.future)), {
        'Gaming': ['Speedruns'],
      });
    });

    test('asked again, Claude suggests another category, and accepting it '
        'keeps it as the user chose', () async {
      final claude = _claude({
        'parent': 'Gaming',
        'child': 'Speedruns',
        'reason': 'Races, not fights',
      });
      final c = container(details: known, keys: claudeKey, claude: claude);
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      final categorizer = c.read(channelCategorizerProvider.notifier);
      const gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');
      expect(categorizer.canAskAi, isTrue);

      final suggestion = await categorizer.suggest(gamer);
      expect(suggestion.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(claude.asked.last, contains('Gaming › Action'));
      await c.read(categoryEditorProvider.notifier).accept(gamer, suggestion);

      final kept = c.read(channelCategoriesProvider).value?['UCg'];
      expect(kept?.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(kept?.userDecision, UserDecision.accepted);
      expect(await c.read(customCategoriesProvider.future), contains('Gaming'));
    });

    test(
      'accepting a new sub-category AI suggests keeps the emoji it gave',
      () async {
        final claude = _claude({
          'parent': 'Gaming',
          'child': 'Retro',
          'emoji': '👾',
          'reason': 'Old games',
        });
        // Only Gamer, whose topics name a sub-category: the run asks Claude
        // for its tags alone, so only asking AI names Retro.
        final c = container(
          details: known,
          keys: claudeKey,
          claude: claude,
          history: TakeoutHistory(watches: [_watch('UCg', 'Gamer')]),
        );
        c.read(historyShownProvider.notifier).markShown();
        await _settle();
        await _runAi(c);
        expect(await c.read(customCategoriesProvider.future), isEmpty);
        const gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');

        final suggestion = await c
            .read(channelCategorizerProvider.notifier)
            .suggest(gamer);
        await c.read(categoryEditorProvider.notifier).accept(gamer, suggestion);

        expect((await c.read(customCategoriesProvider.future))['Gaming'], [
          const SubCategory(name: 'Retro', emoji: '👾'),
        ]);
      },
    );

    test("accepting a variant of a sub-category there is keeps that one's "
        'spelling, and adds none', () async {
      final c = container(details: known, keys: claudeKey);
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      await c
          .read(customCategoriesProvider.notifier)
          .add('Gaming', 'Speedruns');
      const gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');
      const singer = HistoryChannel(channelId: 'UCs', title: 'Singer');

      await c
          .read(categoryEditorProvider.notifier)
          .accept(
            gamer,
            ChannelCategory(
              path: const CategoryPath('Gaming', 'speed-runs'),
              source: CategorySource.claude,
              decidedAt: DateTime.utc(2026, 10),
            ),
          );
      await c
          .read(categoryEditorProvider.notifier)
          .accept(
            singer,
            ChannelCategory(
              path: const CategoryPath('Music', 'Hip-Hop'),
              source: CategorySource.claude,
              decidedAt: DateTime.utc(2026, 10),
            ),
          );

      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Speedruns'));
      expect(paths(c)['UCs'], const CategoryPath('Music', 'Hip hop'));
      expect(subCategoryNames(await c.read(customCategoriesProvider.future)), {
        'Gaming': ['Speedruns'],
      });
    });

    test('adding a variant of a sub-category there is gives the spelling in '
        'use, and adds none', () async {
      final c = container(details: known);
      final custom = c.read(customCategoriesProvider.notifier);
      expect(await custom.add('Gaming', 'Speedruns'), 'Speedruns');

      expect(await custom.add('Gaming', 'speed runs'), 'Speedruns');
      expect(await custom.add('Music', 'hip-hop'), 'Hip hop');
      expect(await custom.add('Gaming', 'Retro'), 'Retro');

      expect(subCategoryNames(await c.read(customCategoriesProvider.future)), {
        'Gaming': ['Speedruns', 'Retro'],
      });
    });

    test("denying a suggestion keeps the category, and it's not asked "
        'about again', () async {
      final c = container(
        details: known,
        keys: claudeKey,
        claude: _claude({'parent': 'Music', 'child': null, 'reason': ''}),
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      const gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');

      await c.read(categoryEditorProvider.notifier).deny(gamer);
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
    await _runAi(c);

    expect(c.read(channelCategorizerProvider.notifier).canAskAi, isFalse);
  });

  test('categories are kept after a restart, and not made again', () async {
    final first = container(details: known);
    first.read(historyShownProvider.notifier).markShown();
    await _settle();
    await _runAi(first);
    first.dispose();

    final again = container(details: const {});
    await again.read(channelCategoriesProvider.future);

    expect(paths(again)['UCg'], const CategoryPath('Gaming', 'Action'));
  });

  group('AI is asked only when Run is clicked', () {
    const claudeKey = AiKeys(anthropic: 'sk-ant-1');
    const knowledge = {'parent': 'Knowledge', 'child': null, 'reason': ''};
    final noTopics = TakeoutHistory(
      watches: [
        for (final id in ['UC1', 'UC2', 'UC3', 'UC4'])
          _watch(id, 'Channel $id'),
      ],
    );

    test("with both keys, opening History categorizes from YouTube's topics "
        'and asks no AI', () async {
      final jev = _Jev();
      final claude = _claude(knowledge);
      final c = container(
        details: known,
        keys: const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-1'),
        jev: jev,
        claude: claude,
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      expect(paths(c)['UCs'], const CategoryPath('Music', 'Pop'));
      expect(jev.requests, 0);
      expect(claude.asked, isEmpty);
    });

    test('Run asks AI, and a second Run asks nothing more', () async {
      final claude = _claude(knowledge);
      final c = container(keys: claudeKey, claude: claude, history: noTopics);
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      expect(claude.asked, isEmpty);

      await _runAi(c);
      expect(claude.kinds, hasLength(4));
      expect(paths(c)['UC4'], const CategoryPath('Knowledge'));

      await _runAi(c);
      expect(claude.kinds, hasLength(4));
    });

    test('Stop keeps the answers already asked for and asks nothing more; '
        'Run again asks only for the rest', () async {
      final hold = Completer<void>();
      final claude = _claude(knowledge, hold: hold);
      final c = container(
        keys: claudeKey,
        claude: claude,
        history: TakeoutHistory(
          watches: [for (var i = 0; i < 100; i++) _watch('UC$i', 'Channel $i')],
        ),
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      expect(claude.kinds, hasLength(60));

      c.read(channelCategorizerProvider.notifier).stop();
      expect(c.read(categorizationProgressProvider).stopping, isTrue);
      hold.complete();
      await _settle();

      expect(claude.kinds, hasLength(60));
      List<CategoryPath> categorized() => [
        for (final path in paths(c).values) ?path,
      ];
      expect(categorized(), hasLength(60));
      final progress = c.read(categorizationProgressProvider);
      expect(progress.running, isFalse);
      expect(progress.interrupted, isTrue);

      await _runAi(c);
      expect(claude.kinds, hasLength(100));
      expect(categorized(), hasLength(100));
      expect(c.read(categorizationProgressProvider).interrupted, isFalse);
    });

    test(
      "subscriptions arriving during the user's run keep it going",
      () async {
        final hold = Completer<void>();
        final claude = _claude(knowledge, hold: hold);
        final c = container(keys: claudeKey, claude: claude, history: noTopics);
        c.read(historyShownProvider.notifier).markShown();
        await _settle();
        await _runAi(c);

        c.read(_subs.notifier).set(const [
          Subscription(
            channelId: 'UCn',
            channelUrl: 'http://www.youtube.com/channel/UCn',
            channelTitle: 'Newsy',
          ),
        ]);
        await _settle();
        hold.complete();
        await _settle();

        expect(claude.kinds, contains('category: Newsy'));
        expect(paths(c)['UC4'], const CategoryPath('Knowledge'));
      },
    );

    test('Jev turned off during the run ends it, rather than Claude taking '
        'over', () async {
      final claude = _claude(knowledge);
      final c = container(
        details: known,
        keys: const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-1'),
        jev: _Jev(failure: const AiKeyRejected()),
        claude: claude,
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      await _runAi(c);

      expect(c.read(aiTierStatusProvider).disabled, {AiService.jev});
      expect(claude.asked, isEmpty);
      expect(c.read(categorizationProgressProvider).interrupted, isTrue);
    });

    test('Claude turned off during the run lets it go on with Jev', () async {
      final c = container(
        details: known,
        keys: const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-1'),
        jev: _Jev(),
        claude: _claude(knowledge, failure: const AiKeyRejected()),
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      await _runAi(c);

      expect(c.read(aiTierStatusProvider).disabled, {AiService.claude});
      expect(
        c
            .read(channelCategoriesProvider)
            .value!
            .values
            .where((category) => category.jevAgreed != null),
        hasLength(2),
      );
      expect(c.read(categorizationProgressProvider).interrupted, isFalse);
    });

    test(
      "a service's pause holds the user's run, not YouTube's categories",
      () async {
        final timers = _Timers();
        final jev = _Jev(failure: const AiOverloaded());
        final c = container(
          keys: const AiKeys(typesafe: 'jv_live_1'),
          jev: jev,
          timers: timers,
          history: TakeoutHistory(watches: [_watch('UCx', 'No topics')]),
        );
        c.read(historyShownProvider.notifier).markShown();
        await _settle();
        await _runAi(c);
        expect(timers.active, hasLength(1));

        await c.read(channelDetailsProvider.notifier).add(known);
        (c.read(takeoutHistoryProvider.notifier) as _Fixed).switchTo(_history);
        await _settle();

        expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      },
    );
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
      await _runAi(c);

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
      await _runAi(c);

      expect(timers.active.single.after, const Duration(seconds: 90));
    });

    test('a stated wait that has all but passed still pauses for a minute, '
        'so a run never starts again at once', () async {
      final timers = _Timers();
      final c = container(
        details: known,
        keys: jevKey,
        jev: _Jev(
          failure: AiRateLimited(
            'Too many requests for now.',
            t0.add(const Duration(milliseconds: 1)),
          ),
        ),
        timers: timers,
        now: () => t0,
      );

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      expect(timers.active.single.after, const Duration(minutes: 1));
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
      await _runAi(c);
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
      await _runAi(c);
      jev.failure = null;

      c.read(_keys.notifier).set(const AiKeys(typesafe: 'jv_live_2'));
      await _settle();

      expect(timers.active, isEmpty);
      expect(agreed(c), 2);
      expect(await pauses().load(now: t0), isEmpty);
    });

    test('a pause kept from before a restart holds AI for the time left, '
        "not YouTube's categories, and its end starts no AI", () async {
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
      expect(paths(c)['UCg'], const CategoryPath('Gaming', 'Action'));
      expect(timers.active.single.after, const Duration(minutes: 3));

      timers.active.single.fire();
      await _settle();
      expect(jev.requests, 0);
    });

    test('Run during a kept pause waits for it to end', () async {
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
        now: () => t0,
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      await _runAi(c);
      expect(jev.requests, 0);

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
      await _runAi(c);

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
      await _runAi(c);
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
      await _runAi(c);

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
        await _runAi(c);

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
      await _runAi(c);

      expect(c.read(aiTierStatusProvider).notice, isNotNull);
      expect(c.read(categorizationProgressProvider).running, isFalse);
    });
  });

  group('clearing AI results', () {
    const claudeKey = AiKeys(anthropic: 'sk-ant-1');

    test('an answer that comes after the clear began is not kept', () async {
      final hold = Completer<void>();
      final claude = _claude(
        {'parent': 'Knowledge', 'child': null, 'reason': ''},
        tags: ['ASMR'],
        hold: hold,
      );
      final c = container(details: known, keys: claudeKey, claude: claude);
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      expect(claude.asked, isNotEmpty);

      final clearing = c.read(aiResultsClearerProvider.notifier).clear();
      hold.complete();
      await clearing;
      await _settle();

      final categories = c.read(channelCategoriesProvider).value ?? const {};
      expect(categories['UCx']?.isAi, isFalse);
      expect(categories['UCx']?.path, isNull);
      expect(categories.values.expand((c) => c.tags), isEmpty);
    });

    test("a clear doesn't wait for the videos' descriptions to finish "
        'coming', () async {
      final c = container(
        details: known,
        keys: claudeKey,
        session: 'UCme',
        videoDetails: _VideoDetails(endless: true),
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      await c
          .read(aiResultsClearerProvider.notifier)
          .clear()
          .timeout(const Duration(seconds: 5));
    });

    test('a service turned off by an answer during a clear starts no run '
        'that lands after it', () async {
      final hold = Completer<void>();
      final jev = _Jev();
      final claude = _claude(
        {'parent': 'Knowledge', 'child': null, 'reason': ''},
        failure: const AiKeyRejected(),
        hold: hold,
      );
      final c = container(
        details: known,
        keys: const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-1'),
        jev: jev,
        claude: claude,
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      final jevAsked = jev.asked.length;

      final clearing = c.read(aiResultsClearerProvider.notifier).clear();
      hold.complete();
      await clearing;
      await _settle();

      expect(jev.asked, hasLength(jevAsked));
      final categories = c.read(channelCategoriesProvider).value ?? const {};
      expect(categories.values.where((c) => c.jevAgreed != null), isEmpty);
    });

    test('after a clear, AI waits for the next Run', () async {
      final claude = _claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      });
      final c = container(details: known, keys: claudeKey, claude: claude);
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      final asked = claude.asked.length;

      await c.read(aiResultsClearerProvider.notifier).clear();
      await _settle();
      expect(claude.asked, hasLength(asked));

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      expect(claude.asked, hasLength(asked));

      await _runAi(c);
      expect(claude.asked.length, greaterThan(asked));
    });
  });

  group('prompts, tags and video descriptions', () {
    const claudeKey = AiKeys(anthropic: 'sk-ant-1');

    /// Channel categories kept on this device before the run.
    void saved(Map<String, ChannelCategory> categories) => setMockStorage(
      entries: {
        EntryBoxes.channelCategories: {
          for (final MapEntry(:key, :value) in categories.entries)
            key: jsonEncode(value.toMap()),
        },
      },
    );

    final decidedAt = DateTime.utc(2026, 9, 30);

    test('a category AI made before prompts were kept is made again once, '
        'then left', () async {
      saved({
        'UCx': ChannelCategory(
          path: const CategoryPath('Knowledge'),
          source: CategorySource.claude,
          tried: const {CategorizationTier.youtube, CategorizationTier.claude},
          decidedAt: decidedAt,
        ),
      });
      final claude = _claude({
        'parent': 'Gaming',
        'child': null,
        'reason': 'Plays games',
      });
      final c = container(details: known, keys: claudeKey, claude: claude);
      final redone = <bool>[];
      c.listen(categorizationProgressProvider, (_, p) {
        if (p.running) redone.add(p.redo);
      });

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      expect(claude.kinds, contains('category: No topics'));
      expect(paths(c)['UCx'], const CategoryPath('Gaming'));
      expect(redone, contains(isTrue));
      final asked = claude.asked.length;

      await _runAi(c);
      expect(claude.asked, hasLength(asked));
    });

    test("a category from YouTube's topics alone isn't made again, and gets "
        'its tags', () async {
      final claude = _claude(
        {'parent': 'Gaming', 'child': null, 'reason': ''},
        tags: ['Mario Kart World'],
      );
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      expect(claude.kinds, contains('tags: Gamer'));
      expect(claude.kinds, isNot(contains('category: Gamer')));
      final gamer = c.read(channelCategoriesProvider).value?['UCg'];
      expect(gamer?.path, const CategoryPath('Gaming', 'Action'));
      expect(gamer?.tags, ['Mario Kart World']);
    });

    test('a category the user accepted keeps it, and gets its tags', () async {
      saved({
        'UCs': ChannelCategory(
          path: const CategoryPath('Music', 'Jazz'),
          source: CategorySource.claude,
          userDecision: UserDecision.accepted,
          decidedAt: decidedAt,
        ),
      });
      final claude = _claude(
        {'parent': 'Gaming', 'child': null, 'reason': ''},
        tags: ['Jazz piano'],
      );
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      expect(claude.kinds, contains('tags: Singer'));
      final singer = c.read(channelCategoriesProvider).value?['UCs'];
      expect(singer?.path, const CategoryPath('Music', 'Jazz'));
      expect(singer?.userDecision, UserDecision.accepted);
      expect(singer?.tags, ['Jazz piano']);
    });

    test('tags the user edited are never asked for again', () async {
      saved({
        'UCs': ChannelCategory(
          path: const CategoryPath('Music', 'Pop'),
          tags: const ['Mine'],
          tagsTried: true,
          tagsEditedByUser: true,
          tagsPrompt: 'an older prompt',
          decidedAt: decidedAt,
        ),
      });
      final claude = _claude(
        {'parent': 'Gaming', 'child': null, 'reason': ''},
        tags: ['Theirs'],
      );
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      expect(claude.kinds.where((k) => k.endsWith('Singer')), isEmpty);
      expect(c.read(channelCategoriesProvider).value?['UCs']?.tags, ['Mine']);
    });

    test('new tags are kept as made by AI', () async {
      final claude = _claude(
        {'parent': 'Gaming', 'child': null, 'reason': ''},
        tags: ['Speedruns'],
      );
      final c = container(details: known, keys: claudeKey, claude: claude);

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);

      final names = await c.read(tagNamesProvider.future);
      expect(names.values.single.name, 'Speedruns');
      expect(names.values.single.origin, NameOrigin.ai);
    });

    group('video descriptions', () {
      final history = TakeoutHistory(
        watches: [
          for (var i = 0; i < 3; i++)
            WatchEntry(
              time: DateTime.utc(2026, 4, 12 - i),
              kind: WatchKind.video,
              title: 'Video $i',
              url: 'https://www.youtube.com/watch?v=vx$i',
              channelTitle: 'No topics',
              channelUrl: 'https://www.youtube.com/channel/UCx',
            ),
        ],
      );

      test('signed in, the missing ones are fetched first, and AI is told '
          'them', () async {
        final videoDetails = _VideoDetails();
        final claude = _claude({
          'parent': 'Knowledge',
          'child': null,
          'reason': '',
        });
        final c = container(
          details: known,
          keys: claudeKey,
          claude: claude,
          session: 'UCme',
          history: history,
          videoDetails: videoDetails,
        );

        c.read(historyShownProvider.notifier).markShown();
        await _settle();
        await _runAi(c);

        expect(videoDetails.asked, {'vx0', 'vx1', 'vx2'});
        expect(claude.asked.single, contains('Fetched about vx1'));
      });

      test('signed out, only the ones kept are told', () async {
        setMockStorage(
          entries: {
            EntryBoxes.videos: {
              'vx1': jsonEncode(
                const Video(
                  videoId: 'vx1',
                  channelId: 'UCx',
                  description: 'Kept about vx1',
                ).toMap(),
              ),
            },
          },
        );
        final videoDetails = _VideoDetails();
        final claude = _claude({
          'parent': 'Knowledge',
          'child': null,
          'reason': '',
        });
        final c = container(
          details: known,
          keys: claudeKey,
          claude: claude,
          history: history,
          videoDetails: videoDetails,
        );
        c.listen(videoMetadataProvider, (_, _) {});

        c.read(historyShownProvider.notifier).markShown();
        await _settle();
        await _runAi(c);

        expect(videoDetails.asked, isEmpty);
        expect(claude.asked.single, contains('Kept about vx1'));
      });
    });

    test('a channel is marked as being asked about while it is, and only '
        'then', () async {
      final hold = Completer<void>();
      final claude = _claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': '',
      }, hold: hold);
      final c = container(details: known, keys: claudeKey, claude: claude);
      c.listen(categorizingChannelsProvider, (_, _) {});

      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      expect(c.read(categorizingChannelsProvider), contains('UCx'));

      hold.complete();
      await _settle();
      expect(c.read(categorizingChannelsProvider), isEmpty);
    });
  });
  group('a run with AI, in waves', () {
    const claudeKey = AiKeys(anthropic: 'sk-ant-1');
    const bothKeys = AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-1');

    /// [count] channels, the first watched most, then fewer and fewer.
    TakeoutHistory many(int count) => TakeoutHistory(
      watches: [
        for (var i = 0; i < count; i++)
          for (var w = 0; w < (i == 0 ? count + 1 : (count - i) ~/ 10 + 1); w++)
            _watch('UC$i', 'Channel $i'),
      ],
    );

    test('asks Claude about channels in requests of at most 20, the most '
        'watched first', () async {
      final claude = _claude({'parent': 'Knowledge'});
      final c = container(keys: claudeKey, claude: claude, history: many(45));
      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      await _runAi(c);

      expect([for (final r in claude.requests) r.channels.length], [20, 20, 5]);
      expect(claude.requests.first.channels.first['channel'], 'Channel 0');
      expect(
        paths(c).values.where((p) => p == const CategoryPath('Knowledge')),
        hasLength(45),
      );
    });

    test('offers Jev the tags Claude named in the waves before', () async {
      final jev = _Jev(agree: 0.9);
      final claude = _claude({'parent': 'Gaming'}, tags: ['Hermitcraft']);
      final c = container(
        details: {
          for (var i = 0; i < 101; i++)
            'UC$i': ChannelDetails(topicUrls: [_topic('Action_game')]),
        },
        keys: bothKeys,
        jev: jev,
        claude: claude,
        history: many(101),
      );
      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      await _runAi(c);

      final tagQuestions = [
        for (final question in jev.asked)
          if (question is JevNoul && question.instructions.contains('tag'))
            question.instructions,
      ];
      expect(tagQuestions, contains(contains('Hermitcraft')));
    });

    test('Stop keeps the requests already sent, and sends no more', () async {
      final hold = Completer<void>();
      final claude = _claude({'parent': 'Knowledge'}, hold: hold);
      final c = container(keys: claudeKey, claude: claude, history: many(100));
      c.read(historyShownProvider.notifier).markShown();
      await _settle();
      await _runAi(c);
      final sent = claude.requests.length;
      expect(sent, inInclusiveRange(1, 3));

      c.read(channelCategorizerProvider.notifier).stop();
      hold.complete();
      await _settle();

      expect(claude.requests, hasLength(sent));
      expect(
        paths(c).values.where((p) => p == const CategoryPath('Knowledge')),
        hasLength(20 * sent),
      );
    });

    test('a billing failure keeps the answers that came, and turns Claude '
        'off', () async {
      var requests = 0;
      final claude = ScriptedClaude(
        answer: (kind, channels) {
          if (++requests > 1) throw const AiBillingProblem('Out of credit.');
          return [
            for (final channel in channels)
              {
                'id': channel['id'],
                'parent': 'Knowledge',
                'child': '',
                'emoji': '',
                'reason': '',
                'tags': const [],
              },
          ];
        },
      );
      final c = container(keys: claudeKey, claude: claude, history: many(45));
      c.read(historyShownProvider.notifier).markShown();
      await _settle();

      await _runAi(c);

      expect(c.read(aiTierStatusProvider).disabled, {AiService.claude});
      expect(
        paths(c).values.where((p) => p == const CategoryPath('Knowledge')),
        hasLength(20),
      );
    });

    group("checks channels for the user's tags", () {
      final decidedAt = DateTime.utc(2026, 9, 30);
      final checkedAt = DateTime.utc(2026, 10, 1);

      ChannelCategory tagged(
        List<String> tags, {
        bool edited = false,
        Set<String> removed = const {},
      }) => ChannelCategory(
        path: const CategoryPath('Gaming', 'Action'),
        tried: const {
          CategorizationTier.youtube,
          CategorizationTier.jev,
          CategorizationTier.claude,
        },
        jevAgreed: 0.9,
        prompts: {
          for (final MapEntry(:key, :value) in currentPrompts.entries)
            if (key == PromptStep.jevCheck) key.name: value,
        },
        tags: tags,
        tagsTried: true,
        tagsEditedByUser: edited,
        tagsRemovedByUser: removed,
        tagsPrompts: {
          for (final MapEntry(:key, :value) in currentPrompts.entries)
            if (key == PromptStep.jevTags) key.name: value,
        },
        tagsCheckedAt: checkedAt,
        decidedAt: decidedAt,
      );

      Future<ProviderContainer> start(_Jev jev) async {
        setMockStorage(
          entries: {
            EntryBoxes.channelCategories: {
              'UCg': jsonEncode(tagged(['Old']).toMap()),
              'UCs': jsonEncode(tagged(['Mine'], edited: true).toMap()),
              'UCx': jsonEncode(
                tagged(const [], edited: true, removed: {'mine'}).toMap(),
              ),
            },
          },
        );
        final c = container(
          details: known,
          keys: const AiKeys(typesafe: 'jv_live_1'),
          jev: jev,
          now: () => checkedAt.add(const Duration(days: 2)),
        );
        await c
            .read(tagNamesProvider.notifier)
            .put(
              'mine',
              TagName(
                name: 'Mine',
                origin: NameOrigin.user,
                meaning: 'What I watch on Sundays',
                changedAt: checkedAt.add(const Duration(days: 1)),
              ),
            );
        await c
            .read(tagNamesProvider.notifier)
            .put(
              'old',
              TagName(
                name: 'Old',
                origin: NameOrigin.user,
                meaning: 'Changed since',
                changedAt: checkedAt.add(const Duration(days: 1)),
              ),
            );
        c.read(historyShownProvider.notifier).markShown();
        await _settle();
        return c;
      }

      Map<String, List<String>> tags(ProviderContainer c) => {
        for (final MapEntry(:key, :value)
            in c.read(channelCategoriesProvider).value!.entries)
          key: value.tags,
      };

      test('adding one Jev is sure of and taking off one it is sure no '
          'longer fits; on an edited channel, keeping what the user added '
          'and never putting back what they removed', () async {
        final c = await start(_Jev(agree: 0.9, tagFits: {'Mine': 0.9}));

        await _runAi(c);

        expect(tags(c), {
          'UCg': ['Mine'],
          'UCs': ['Mine'],
          'UCx': isEmpty,
        });
      });

      test('once: the next run checks nothing more, until a meaning '
          'changes', () async {
        final jev = _Jev(agree: 0.9, tagFits: {'Mine': 0.9});
        final c = await start(jev);
        await _runAi(c);
        final asked = jev.asked.length;
        expect(asked, greaterThan(0));

        await _runAi(c);
        expect(jev.asked, hasLength(asked));

        await c
            .read(tagEditorProvider.notifier)
            .setMeaning('mine', 'What I watch on Saturdays');
        await _runAi(c);
        expect(jev.asked.length, greaterThan(asked));
      });
    });
  });
}
