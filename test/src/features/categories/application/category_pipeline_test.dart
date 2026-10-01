import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/category_pipeline.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/prompt_fingerprints.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/model_capabilities.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';

String _topic(String slug) => 'https://en.wikipedia.org/wiki/$slug';

/// Jev, answering from a script: how likely yes is for each category it's
/// asked about, and the option it picks with how likely each is.
class _Jev extends TypeSafeRepository {
  _Jev({this.fits = const {}, this.parent, this.child});

  /// How likely yes is, by the category's label.
  final Map<String, double> fits;
  final Map<String, double>? parent;
  final Map<String, double>? child;

  /// The questions asked, per request.
  final requests = <Map<String, JevQuestion>>[];

  @override
  Future<Map<String, JevAnswer>> ask({
    required String apiKey,
    required Object state,
    required Map<String, JevQuestion> questions,
  }) async {
    requests.add(questions);
    return {
      for (final MapEntry(:key, :value) in questions.entries)
        key: switch (value) {
          JevNoul(:final instructions) => NoulAnswer(
            fits.entries
                    .where((f) => instructions.contains('"${f.key}"'))
                    .firstOrNull
                    ?.value ??
                0,
          ),
          JevChoice(:final options) => _choose(
            options,
            key == 'parent' ? parent : child,
          ),
        },
    };
  }

  /// Picks the likeliest of [options] by the names in [odds].
  static ChoiceAnswer _choose(
    Map<String, String?> options,
    Map<String, double>? odds,
  ) {
    String keyOf(String name) => options.entries
        .firstWhere(
          (o) => o.key == name || (o.value?.startsWith(name) ?? false),
          orElse: () => options.entries.first,
        )
        .key;
    final probabilities = {
      for (final MapEntry(:key, :value) in (odds ?? const {}).entries)
        keyOf(key): value,
    };
    // Not scripted: no confidence in anything.
    if (probabilities.isEmpty) {
      return ChoiceAnswer(
        choice: options.keys.first,
        probabilities: {options.keys.first: 0},
        confidence: 0,
      );
    }
    final best = probabilities.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return ChoiceAnswer(
      choice: best.key,
      probabilities: probabilities,
      confidence: best.value,
    );
  }
}

/// Claude, answering a category request with [answer] and a tags-only one
/// with [tags], or failing with [failure], and keeping what it was asked.
class _Claude extends AnthropicRepository {
  _Claude(this.answer, {this.tags = const [], this.failure});

  final Map<String, Object?> answer;
  final List<Object?> tags;
  final AiFailure? failure;
  final asked = <String>[];

  /// What each request asked for: 'category' or 'tags'.
  final kinds = <String>[];

  @override
  Future<Map<String, Object?>> structured({
    required String apiKey,
    required ModelCapabilities model,
    required String system,
    required String user,
    required Map<String, Object?> schema,
  }) async {
    asked.add(user);
    final tagsOnly = !(schema['properties']! as Map).containsKey('parent');
    kinds.add(tagsOnly ? 'tags' : 'category');
    if (failure case final failure?) throw failure;
    return tagsOnly ? {'tags': tags} : answer;
  }
}

/// Fingerprints that name their step, so a result's are easy to read.
final _fingerprints = {
  for (final step in PromptStep.values) step: 'fp-${step.name}',
};

CategoryPipeline _withClaude(
  _Claude claude, {
  _Jev? jev,
  Map<String, String> tagSpellings = const {},
}) => CategoryPipeline(
  taxonomy: youtubeTaxonomy.withCustom({
    'Gaming': ['Speedruns'],
  }),
  tagSpellings: tagSpellings,
  fingerprints: _fingerprints,
  jev: jev == null ? null : (repository: jev, apiKey: 'jv_live_1'),
  claude: (
    repository: claude,
    apiKey: 'sk-ant-1',
    model: const ModelCapabilities(
      id: 'claude-haiku-4-5',
      structuredOutputs: true,
      lowEffort: false,
    ),
  ),
);

ChannelInput _input({List<String> topics = const []}) => (
  key: 'UCg',
  topicUrls: topics,
  evidence: const ChannelEvidence(
    title: 'Speedy',
    titles: ['Any% in 10 minutes'],
  ),
);

CategoryPipeline _pipeline(_Jev jev) => CategoryPipeline(
  taxonomy: youtubeTaxonomy.withCustom({
    'Gaming': ['Speedruns'],
  }),
  fingerprints: _fingerprints,
  jev: (repository: jev, apiKey: 'jv_live_1'),
);

void main() {
  test("without Jev, YouTube's category is taken as it is", () async {
    final category = await CategoryPipeline(
      taxonomy: youtubeTaxonomy,
    ).categorize(_input(topics: [_topic('Action_game')]));

    expect(category.path, const CategoryPath('Gaming', 'Action'));
    expect(category.source, CategorySource.youtube);
    expect(category.tried, {CategorizationTier.youtube});
  });

  test("when Jev agrees with YouTube's category, it's kept, with how sure "
      'Jev is', () async {
    final jev = _Jev(fits: {'Gaming › Action': 0.9});

    final category = await _pipeline(
      jev,
    ).categorize(_input(topics: [_topic('Action_game')]));

    expect(category.path, const CategoryPath('Gaming', 'Action'));
    expect(category.source, CategorySource.youtube);
    expect(category.jevAgreed, 0.9);
    expect(category.tried, {
      CategorizationTier.youtube,
      CategorizationTier.jev,
    });
    // One request did it.
    expect(jev.requests, hasLength(1));
  });

  test('of several YouTube categories, the one Jev agrees with most is '
      'kept', () async {
    final jev = _Jev(
      fits: {'Gaming › Action': 0.7, 'Gaming › Role-playing': 0.95},
    );

    final category = await _pipeline(jev).categorize(
      _input(
        topics: [_topic('Action_game'), _topic('Role-playing_video_game')],
      ),
    );

    expect(category.path, const CategoryPath('Gaming', 'Role-playing'));
  });

  test('when Jev disagrees, it picks from every category, including ones '
      'AI made before', () async {
    final jev = _Jev(
      fits: {'Gaming › Action': 0.2},
      parent: {'Gaming': 0.9, 'Music': 0.1},
      child: {'Speedruns': 0.8, 'Action': 0.15},
    );

    final category = await _pipeline(
      jev,
    ).categorize(_input(topics: [_topic('Action_game')]));

    expect(category.path, const CategoryPath('Gaming', 'Speedruns'));
    expect(category.source, CategorySource.jev);
    expect(category.isAi, isTrue);
    expect(category.confidence, closeTo(sqrt(0.9 * 0.8), 0.001));
    expect([
      for (final r in category.runnersUp) r.path,
    ], contains(const CategoryPath('Gaming', 'Action')));
    expect(category.jevAgreed, 0.2);
  });

  test('without YouTube topics, Jev picks from the names and titles', () async {
    final jev = _Jev(
      parent: {'Gaming': 0.95, 'Music': 0.05},
      child: {'Speedruns': 0.9, 'Action': 0.1},
    );

    final category = await _pipeline(jev).categorize(_input());

    expect(category.path, const CategoryPath('Gaming', 'Speedruns'));
    expect(category.hadTopics, isFalse);
    // No YouTube category to check.
    expect(jev.requests.first.values.whereType<JevNoul>(), isEmpty);
  });

  test('a category with no sub-categories is picked in one step', () async {
    final jev = _Jev(parent: {'Knowledge': 0.8, 'Gaming': 0.2});

    final category = await _pipeline(jev).categorize(_input());

    expect(category.path, const CategoryPath('Knowledge'));
    expect(category.confidence, closeTo(0.8, 0.001));
    expect(jev.requests, hasLength(1));
  });

  test(
    "when none fits better than the category itself, that's the pick",
    () async {
      final jev = _Jev(
        parent: {'Gaming': 0.9, 'Music': 0.1},
        child: {'None': 0.85, 'Action': 0.15},
      );

      final category = await _pipeline(jev).categorize(_input());

      expect(category.path, const CategoryPath('Gaming'));
    },
  );

  test("when Jev isn't sure of its own pick either, YouTube's category "
      'stays', () async {
    final jev = _Jev(
      fits: {'Gaming › Action': 0.3},
      parent: {'Gaming': 0.5, 'Music': 0.5},
      child: {'Speedruns': 0.4, 'Action': 0.6},
    );

    final category = await _pipeline(
      jev,
    ).categorize(_input(topics: [_topic('Action_game')]));

    expect(category.path, const CategoryPath('Gaming', 'Action'));
    expect(category.source, CategorySource.youtube);
    expect(category.jevAgreed, 0.3);
  });

  group('Claude', () {
    test('names the category when Jev disagrees and is unsure of its own '
        'pick, with its reason', () async {
      final claude = _Claude({
        'parent': 'Gaming',
        'child': 'speedruns',
        'reason': 'Races through games',
      });
      final pipeline = _withClaude(
        claude,
        jev: _Jev(
          fits: {'Gaming › Action': 0.2},
          parent: {'Gaming': 0.5, 'Music': 0.5},
          child: {'Speedruns': 0.5, 'Action': 0.5},
        ),
      );

      final category = await pipeline.categorize(
        _input(topics: [_topic('Action_game')]),
      );

      // The one there is, as it's spelled.
      expect(category.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(category.source, CategorySource.claude);
      expect(category.reason, 'Races through games');
      expect(category.jevAgreed, 0.2);
      expect(category.tried, containsAll(CategorizationTier.values));
      expect(pipeline.takeLearned(), isEmpty);
    });

    test('is asked only for tags when Jev agrees, and they come with the '
        'category', () async {
      final claude = _Claude(
        {'parent': 'Music', 'child': null, 'reason': ''},
        tags: ['Mario Kart World', 'Speedruns'],
      );

      final category = await _withClaude(
        claude,
        jev: _Jev(fits: {'Gaming › Action': 0.9}),
      ).categorize(_input(topics: [_topic('Action_game')]));

      expect(claude.kinds, ['tags']);
      expect(claude.asked.single, contains('Gaming › Action'));
      expect(category.path, const CategoryPath('Gaming', 'Action'));
      expect(category.tags, ['Mario Kart World', 'Speedruns']);
      expect(category.tagsTried, isTrue);
      expect(category.tagsPrompt, 'fp-claudeTags');
    });

    test('without Jev, is asked only for tags when YouTube gives a '
        'sub-category', () async {
      final claude = _Claude({'parent': 'Music', 'child': null, 'reason': ''});

      final category = await _withClaude(
        claude,
      ).categorize(_input(topics: [_topic('Action_game')]));

      expect(category.path, const CategoryPath('Gaming', 'Action'));
      expect(claude.kinds, ['tags']);
    });

    test('without Jev, names the category YouTube gives none for', () async {
      final claude = _Claude({
        'parent': 'Knowledge',
        'child': null,
        'reason': 'Explains how things work',
      });

      final category = await _withClaude(claude).categorize(_input());

      expect(category.path, const CategoryPath('Knowledge'));
      expect(category.source, CategorySource.claude);
    });

    test('a new sub-category it names joins the categories', () async {
      final pipeline = _withClaude(
        _Claude({
          'parent': 'Gaming',
          'child': 'Retro game  speedruns ',
          'reason': 'Old games, fast',
        }),
      );

      final category = await pipeline.categorize(_input());

      expect(
        category.path,
        const CategoryPath('Gaming', 'Retro game speedruns'),
      );
      expect(pipeline.takeLearned(), [(path: category.path!, emoji: null)]);
      expect(
        pipeline.taxonomy.childrenOf('Gaming'),
        contains('Retro game speedruns'),
      );
    });

    test("a variant of YouTube's sub-category gets YouTube's spelling, and "
        'nothing is learned', () async {
      final pipeline = _withClaude(
        _Claude({'parent': 'Music', 'child': 'Hip-Hop', 'reason': 'Beats'}),
      );

      final category = await pipeline.categorize(_input());

      expect(category.path, const CategoryPath('Music', 'Hip hop'));
      expect(pipeline.takeLearned(), isEmpty);
    });

    test('a variant of a kept sub-category reuses its spelling', () async {
      final pipeline = _withClaude(
        _Claude({
          'parent': 'Gaming',
          'child': 'Speed-runs',
          'reason': 'Races through games',
        }),
      );

      final category = await pipeline.categorize(_input());

      expect(category.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(pipeline.takeLearned(), isEmpty);
    });

    test('a new name for a sub-category there is already, as Jev finds, '
        'reuses that one', () async {
      final pipeline = _withClaude(
        _Claude({
          'parent': 'Gaming',
          'child': 'Speedrunning',
          'reason': 'Races through games',
        }),
        jev: _Jev(
          parent: {'Gaming': 0.5, 'Music': 0.5},
          child: {'Speedruns': 0.9, 'Action': 0.1},
        ),
      );

      final category = await pipeline.categorize(_input());

      expect(category.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(pipeline.takeLearned(), isEmpty);
    });

    test('asked again, is told the category it had is wrong', () async {
      final claude = _Claude({
        'parent': 'Gaming',
        'child': 'Speedruns',
        'reason': 'Races, not fights',
      });

      final suggestion = await _withClaude(claude).suggestInstead(
        _input(topics: [_topic('Action_game')]),
        const CategoryPath('Gaming', 'Action'),
      );

      expect(suggestion.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(suggestion.source, CategorySource.claude);
      expect(claude.asked.single, contains('Gaming › Action'));
    });
  });

  group('tags', () {
    test('come with the category when Claude names it, in one call', () async {
      final claude = _Claude({
        'parent': 'Gaming',
        'child': 'Speedruns',
        'reason': 'Races',
        'tags': ['Super Metroid', 'Any%'],
      });

      final category = await _withClaude(claude).categorize(_input());

      expect(claude.kinds, ['category']);
      expect(category.tags, ['Super Metroid', 'Any%']);
      expect(category.tagsPrompt, 'fp-claudeCategory');
    });

    test('are spelled as the tags there are', () async {
      final claude = _Claude({
        'parent': 'Gaming',
        'child': 'Speedruns',
        'reason': 'Races',
        'tags': ['mario-kart world'],
      });

      final category = await _withClaude(
        claude,
        tagSpellings: {'mariokartworld': 'Mario Kart World'},
      ).categorize(_input());

      expect(category.tags, ['Mario Kart World']);
    });

    test('are none, and not tried, without Claude', () async {
      final category = await _pipeline(
        _Jev(fits: {'Gaming › Action': 0.9}),
      ).categorize(_input(topics: [_topic('Action_game')]));

      expect(category.tags, isEmpty);
      expect(category.tagsTried, isFalse);
      expect(category.tagsPrompt, isNull);
    });

    test("alone keep the channel's category", () async {
      final claude = _Claude({}, tags: ['ASMR']);
      final current = ChannelCategory(
        path: const CategoryPath('Music', 'Jazz'),
        source: CategorySource.user,
        decidedAt: DateTime.utc(2026, 10, 1),
      );

      final tagged = await _withClaude(claude).retag(_input(), current);

      expect(tagged.path, const CategoryPath('Music', 'Jazz'));
      expect(tagged.source, CategorySource.user);
      expect(tagged.tags, ['ASMR']);
      expect(tagged.tagsTried, isTrue);
      expect(claude.asked.single, contains('Music › Jazz'));
    });

    test('alone, with no usable answer, are none, but tried', () async {
      final claude = _Claude({}, failure: const AiNoAnswer());
      final current = ChannelCategory(
        path: const CategoryPath('Music'),
        decidedAt: DateTime.utc(2026, 10, 1),
      );

      final tagged = await _withClaude(claude).retag(_input(), current);

      expect(tagged.tags, isEmpty);
      expect(tagged.tagsTried, isTrue);
      expect(tagged.tagsPrompt, 'fp-claudeTags');
    });
  });

  group('each result keeps the fingerprints of the prompts asked', () {
    test("none for YouTube's alone", () async {
      final category = await CategoryPipeline(
        taxonomy: youtubeTaxonomy,
        fingerprints: _fingerprints,
      ).categorize(_input(topics: [_topic('Action_game')]));

      expect(category.prompts, isEmpty);
    });

    test("Jev's check, when it agrees", () async {
      final category = await _pipeline(
        _Jev(fits: {'Gaming › Action': 0.9}),
      ).categorize(_input(topics: [_topic('Action_game')]));

      expect(category.prompts, {'jevCheck': 'fp-jevCheck'});
    });

    test("Jev's check and pick, when it picks", () async {
      final category = await _pipeline(
        _Jev(
          fits: {'Gaming › Action': 0.1},
          parent: {'Gaming': 0.9},
          child: {'Speedruns': 0.9},
        ),
      ).categorize(_input(topics: [_topic('Action_game')]));

      expect(category.prompts, {
        'jevCheck': 'fp-jevCheck',
        'jevPick': 'fp-jevPick',
      });
    });

    test("every step, when Claude names a new one Jev checks", () async {
      final category = await _withClaude(
        _Claude({
          'parent': 'Gaming',
          'child': 'Speedrunning',
          'reason': 'Races',
        }),
        jev: _Jev(
          parent: {'Gaming': 0.5, 'Music': 0.5},
          child: {'Speedruns': 0.5, 'Action': 0.5},
        ),
      ).categorize(_input());

      expect(category.prompts.keys.toSet(), {
        'jevCheck',
        'jevPick',
        'claudeCategory',
        'jevNameCheck',
      });
    });
  });

  test("which model answers doesn't change the prompts kept", () async {
    Future<Map<String, String>> promptsWith(ModelCapabilities model) async {
      final category = await CategoryPipeline(
        taxonomy: youtubeTaxonomy,
        claude: (
          repository: _Claude({
            'parent': 'Knowledge',
            'child': null,
            'reason': '',
          }),
          apiKey: 'sk-ant-1',
          model: model,
        ),
      ).categorize(_input());
      return category.prompts;
    }

    expect(
      await promptsWith(
        const ModelCapabilities(
          id: 'claude-haiku-4-5',
          structuredOutputs: true,
          lowEffort: false,
        ),
      ),
      await promptsWith(
        const ModelCapabilities(
          id: 'claude-sonnet-5-5',
          structuredOutputs: true,
          lowEffort: true,
          maxTokens: 512,
        ),
      ),
    );
  });

  test('a new sub-category Claude names keeps its emoji', () async {
    final pipeline = _withClaude(
      _Claude({
        'parent': 'Gaming',
        'child': 'Retro',
        'emoji': '👾',
        'reason': 'Old games',
      }),
    );

    await pipeline.categorize(_input());

    expect(pipeline.takeLearned(), [
      (path: const CategoryPath('Gaming', 'Retro'), emoji: '👾'),
    ]);
  });

  test('asked again with only Jev, Jev picks something other than the '
      'category it had', () async {
    final jev = _Jev(
      parent: {'Gaming': 0.9, 'Music': 0.1},
      child: {'Speedruns': 0.7, 'Racing': 0.3},
    );

    final suggestion = await _pipeline(jev).suggestInstead(
      _input(topics: [_topic('Action_game')]),
      const CategoryPath('Gaming', 'Action'),
    );

    expect(suggestion.path, const CategoryPath('Gaming', 'Speedruns'));
    expect(suggestion.source, CategorySource.jev);
    final childOptions = (jev.requests.last['child']! as JevChoice).options;
    expect(childOptions.values, isNot(contains('Action')));
  });

  group("Jev's options", () {
    /// A pipeline over Knowledge with [children], asking [jev], with
    /// [usage] channels per path.
    CategoryPipeline knowledge(
      List<String> children,
      _Jev jev, {
      Map<CategoryPath, int> usage = const {},
      _Claude? claude,
    }) => CategoryPipeline(
      taxonomy: youtubeTaxonomy.withCustom({'Knowledge': children}),
      usage: usage,
      jev: (repository: jev, apiKey: 'jv_live_1'),
      claude: claude == null
          ? null
          : (
              repository: claude,
              apiKey: 'sk-ant-1',
              model: const ModelCapabilities(
                id: 'claude-haiku-4-5',
                structuredOutputs: true,
                lowEffort: false,
              ),
            ),
    );

    JevChoice asked(_Jev jev, String question) =>
        jev.requests.lastWhere(
              (request) => request.containsKey(question),
            )[question]!
            as JevChoice;

    test('names that read alike as keys are options of their own, and a '
        'pick maps back to the one picked', () async {
      final jev = _Jev(parent: {'Knowledge': 0.9}, child: {'C++': 0.9});

      final category = await knowledge(['C#', 'C++'], jev).categorize(_input());

      expect(category.path, const CategoryPath('Knowledge', 'C++'));
      expect(asked(jev, 'child').options.values, containsAll(['C#', 'C++']));
    });

    test('names in other scripts are options of their own', () async {
      final jev = _Jev(parent: {'Knowledge': 0.9}, child: {'Химия': 0.9});

      final category = await knowledge([
        'Физика',
        'Химия',
      ], jev).categorize(_input());

      expect(category.path, const CategoryPath('Knowledge', 'Химия'));
      expect(
        asked(jev, 'child').options.values,
        containsAll(['Физика', 'Химия']),
      );
    });

    test('a category with more sub-categories than Jev takes offers the '
        'most used, and "none of these"', () async {
      final topics = [for (var i = 1; i <= 300; i++) 'Topic $i'];
      final jev = _Jev(parent: {'Knowledge': 0.9}, child: {'Topic 300': 0.9});

      final category = await knowledge(
        topics,
        jev,
        usage: {const CategoryPath('Knowledge', 'Topic 300'): 9},
      ).categorize(_input());

      final options = asked(jev, 'child').options;
      expect(options, hasLength(JevChoice.maxOptions));
      expect(options.keys, contains('_none'));
      expect(options.values, contains('Topic 300'));
      expect(options.values, isNot(contains('Topic 299')));
      expect(category.path, const CategoryPath('Knowledge', 'Topic 300'));
    });

    test("Jev's check of a name Claude gives offers at most as many as it "
        'takes', () async {
      final topics = [for (var i = 1; i <= 300; i++) 'Topic $i'];
      final jev = _Jev(parent: {'Knowledge': 0.5, 'Music': 0.5});

      await knowledge(
        topics,
        jev,
        claude: _Claude({
          'parent': 'Knowledge',
          'child': 'Something new',
          'reason': 'New',
        }),
      ).categorize(_input());

      expect(
        asked(jev, 'same').options.length,
        lessThanOrEqualTo(JevChoice.maxOptions),
      );
    });
  });
}
