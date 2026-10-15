import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/category_pipeline.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/prompt_fingerprints.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/model_capabilities.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/name_key.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/categorization_plan.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_candidates.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';

import '../ai_fakes.dart';

String _topic(String slug) => 'https://en.wikipedia.org/wiki/$slug';

typedef _Jev = ScriptedJev;

/// Claude answering a category request with [answer] and a tags request
/// with [tags], or failing with [failure].
ScriptedClaude _claude(
  Map<String, Object?> answer, {
  List<Object?> tags = const [],
  AiFailure? failure,
}) => ScriptedClaude(
  category: answer,
  tags: [...tags, ...?(answer['tags'] as List<Object?>?)],
  failure: failure,
);

/// What each request [claude] was sent asked for: 'category' or 'tags'.
List<String> _kinds(ScriptedClaude claude) => [
  for (final request in claude.requests) request.kind,
];

/// Fingerprints that name their step, so a result's are easy to read.
final _fingerprints = {
  for (final step in PromptStep.values) step: 'fp-${step.name}',
};

CategoryPipeline _withClaude(ScriptedClaude claude, {_Jev? jev}) =>
    CategoryPipeline(
      taxonomy: youtubeTaxonomy.withCustom({
        'Gaming': ['Speedruns'],
      }),
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
      final claude = _claude({
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
      final claude = _claude(
        {'parent': 'Music', 'child': null, 'reason': ''},
        tags: ['Mario Kart World', 'Speedruns'],
      );

      final category = await _withClaude(
        claude,
        jev: _Jev(fits: {'Gaming › Action': 0.9}),
      ).categorize(_input(topics: [_topic('Action_game')]));

      expect(_kinds(claude), ['tags']);
      expect(claude.asked.single, contains('Gaming › Action'));
      expect(category.path, const CategoryPath('Gaming', 'Action'));
      expect(category.tags, ['Mario Kart World', 'Speedruns']);
      expect(category.tagsTried, isTrue);
      expect(category.tagsPrompts, {'claudeTags': 'fp-claudeTags'});
    });

    test('without Jev, is asked only for tags when YouTube gives a '
        'sub-category', () async {
      final claude = _claude({'parent': 'Music', 'child': null, 'reason': ''});

      final category = await _withClaude(
        claude,
      ).categorize(_input(topics: [_topic('Action_game')]));

      expect(category.path, const CategoryPath('Gaming', 'Action'));
      expect(_kinds(claude), ['tags']);
    });

    test('without Jev, names the category YouTube gives none for', () async {
      final claude = _claude({
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
        _claude({
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
        _claude({'parent': 'Music', 'child': 'Hip-Hop', 'reason': 'Beats'}),
      );

      final category = await pipeline.categorize(_input());

      expect(category.path, const CategoryPath('Music', 'Hip hop'));
      expect(pipeline.takeLearned(), isEmpty);
    });

    test('a variant of a kept sub-category reuses its spelling', () async {
      final pipeline = _withClaude(
        _claude({
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
        _claude({
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
      final claude = _claude({
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
      final claude = _claude({
        'parent': 'Gaming',
        'child': 'Speedruns',
        'reason': 'Races',
        'tags': ['Super Metroid', 'Any%'],
      });

      final category = await _withClaude(claude).categorize(_input());

      expect(_kinds(claude), ['category']);
      expect(category.tags, ['Super Metroid', 'Any%']);
      expect(category.tagsPrompts, {'claudeTags': 'fp-claudeTags'});
    });

    test('are spelled as the tags there are', () async {
      final claude = _claude({
        'parent': 'Gaming',
        'child': 'Speedruns',
        'reason': 'Races',
        'tags': ['mario-kart world'],
      });

      final category = await _withClaude(claude).categorize(
        _input(),
        tags: TagIndex.of({
          'mariokartworld': const TagName(name: 'Mario Kart World'),
        }, const {}),
      );

      expect(category.tags, ['Mario Kart World']);
    });

    test('are none with only Jev and no tags to offer it, the channel '
        'waiting for Claude', () async {
      final category = await _pipeline(
        _Jev(fits: {'Gaming › Action': 0.9}),
      ).categorize(_input(topics: [_topic('Action_game')]));

      expect(category.tags, isEmpty);
      expect(category.tagsAwaitClaude, isTrue);
      expect(category.tagsPrompts, isEmpty);
    });

    test("alone keep the channel's category", () async {
      final claude = _claude({}, tags: ['ASMR']);
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
      final claude = _claude({}, failure: const AiNoAnswer());
      final current = ChannelCategory(
        path: const CategoryPath('Music'),
        decidedAt: DateTime.utc(2026, 10, 1),
      );

      final tagged = await _withClaude(claude).retag(_input(), current);

      expect(tagged.tags, isEmpty);
      expect(tagged.tagsTried, isTrue);
      expect(tagged.tagsPrompts, {'claudeTags': 'fp-claudeTags'});
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
        _claude({
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
          repository: _claude({
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
      _claude({
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
      ScriptedClaude? claude,
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
        claude: _claude({
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

  group('tags from Jev first', () {
    final tags = TagIndex.of({
      'speedruns': const TagName(
        name: 'Speedruns',
        meaning: 'Finishing games as fast as possible',
      ),
      'nintendo': const TagName(name: 'Nintendo'),
    }, const {});
    final agreeing = {'Gaming › Action': 0.9};

    test("come from the tags there are when Jev finds they fit, and Claude "
        "isn't asked", () async {
      final claude = _claude(const {});

      final category = await _withClaude(
        claude,
        jev: _Jev(fits: {...agreeing, 'Speedruns': 0.8}),
      ).categorize(_input(topics: [_topic('Action_game')]), tags: tags);

      expect(category.tags, ['Speedruns']);
      expect(claude.requests, isEmpty);
      expect(category.tagsPrompts, {'jevTags': 'fp-jevTags'});
    });

    test(
      'are none when nothing fits and Jev finds nothing else to name',
      () async {
        final claude = _claude(const {});

        final category = await _withClaude(
          claude,
          jev: _Jev(fits: agreeing, other: 0.1),
        ).categorize(_input(topics: [_topic('Action_game')]), tags: tags);

        expect(category.tags, isEmpty);
        expect(category.tagsTried, isTrue);
        expect(claude.requests, isEmpty);
      },
    );

    test("come from Claude too when Jev finds something no tag names: it's "
        'told the tags found, and adds what they miss', () async {
      final claude = _claude(const {}, tags: ['Super Metroid']);

      final category = await _withClaude(
        claude,
        jev: _Jev(fits: {...agreeing, 'Speedruns': 0.8}, other: 0.9),
      ).categorize(_input(topics: [_topic('Action_game')]), tags: tags);

      final told = claude.requests.single.channels.single;
      expect(told['tags_found'], ['Speedruns']);
      expect(category.tags, ['Speedruns', 'Super Metroid']);
      expect(category.tagsPrompts, {
        'jevTags': 'fp-jevTags',
        'claudeTags': 'fp-claudeTags',
      });
    });

    test("Claude's repeats of the tags found take none of the room left for "
        'the tags it adds', () async {
      final found = TagIndex.of({
        for (final name in ['VTuber', 'Singing', 'Streaming'])
          nameKey(name): TagName(name: name, meaning: 'A $name channel'),
      }, const {});
      final pipeline = _withClaude(
        _claude(
          const {},
          tags: ['VTuber', 'Singing', 'Phase Connect', 'Cover Artist'],
        ),
        jev: _Jev(
          fits: {...agreeing, 'VTuber': 0.9, 'Singing': 0.8, 'Streaming': 0.7},
          other: 0.9,
        ),
      );

      final category = await pipeline.categorize(
        _input(topics: [_topic('Action_game')]),
        tags: found,
      );

      expect(category.tags, [
        'VTuber',
        'Singing',
        'Streaming',
        'Phase Connect',
        'Cover Artist',
      ]);
      expect(
        [for (final tag in pipeline.takeNamedTags()) tag.name],
        ['Phase Connect', 'Cover Artist'],
      );
    });

    test(
      "Jev's answers about a channel's tags are reported as they come",
      () async {
        final told = <(String, int, Map<String, double>, double)>[];
        final pipeline = CategoryPipeline(
          taxonomy: youtubeTaxonomy.withCustom({
            'Gaming': ['Speedruns'],
          }),
          fingerprints: _fingerprints,
          jev: (
            repository: _Jev(fits: {...agreeing, 'Speedruns': 0.8}, other: 0.3),
            apiKey: 'jv_live_1',
          ),
          onJevTags: (key, offered, yes, other) =>
              told.add((key, offered, yes, other)),
        );

        await pipeline.categorize(
          _input(topics: [_topic('Action_game')]),
          tags: tags,
        );

        final (key, offered, yes, other) = told.single;
        expect((key, offered, other), ('UCg', 2, 0.3));
        expect(yes, {'speedruns': 0.8, 'nintendo': 0.0});
      },
    );

    test('with only Jev, keep what Jev found, the channel waiting for '
        'Claude to name the rest', () async {
      final category = await _pipeline(
        _Jev(fits: {...agreeing, 'Speedruns': 0.8}, other: 0.9),
      ).categorize(_input(topics: [_topic('Action_game')]), tags: tags);

      expect(category.tags, ['Speedruns']);
      expect(category.tagsAwaitClaude, isTrue);
    });

    test("come with Claude's category when Jev can't settle it, with their "
        "meanings, and Jev isn't asked for them", () async {
      final jev = _Jev(parent: {'Gaming': 0.3}, child: {'Speedruns': 0.3});
      final pipeline = _withClaude(
        _claude({
          'parent': 'Gaming',
          'tags': [
            {'name': 'Any%', 'meaning': 'Beating a game by any means'},
          ],
        }),
        jev: jev,
      );

      final category = await pipeline.categorize(_input(), tags: tags);

      expect(category.tags, ['Any%']);
      expect(pipeline.takeNamedTags(), [
        (name: 'Any%', meaning: 'Beating a game by any means'),
      ]);
      expect(
        jev.requests.where((questions) => questions.containsKey('other')),
        isEmpty,
      );
    });
  });

  group('Claude asked about many channels', () {
    ChannelInput channel(int i) => (
      key: 'UC$i',
      topicUrls: const [],
      evidence: ChannelEvidence(title: 'Channel $i', titles: ['Video $i']),
    );
    final none = TagIndex.of(const {}, const {});

    Future<List<ClaudeTicket>> tickets(
      CategoryPipeline pipeline,
      int count,
    ) async => [
      for (var i = 0; i < count; i++)
        switch (await pipeline.prepare(channel(i), (
          work: ChannelWork.categorize,
          redo: false,
          checkTags: false,
        ), tags: none)) {
          NeedsClaude(:final ticket) => ticket,
          _ => throw StateError('Expected a ticket'),
        },
    ];

    Future<Map<String, ChannelCategory>> ask(
      CategoryPipeline pipeline,
      List<ClaudeTicket> tickets, {
      bool Function()? stopped,
    }) async {
      final results = <String, ChannelCategory>{};
      await pipeline.askClaude(
        tickets,
        stopped: stopped ?? () => false,
        tags: none,
        onResult: (key, result) => results[key] = result,
      );
      return results;
    }

    test('are asked in requests of at most 20, in order', () async {
      final claude = _claude({'parent': 'Knowledge'});
      final pipeline = _withClaude(claude);

      final results = await ask(pipeline, await tickets(pipeline, 45));

      expect([for (final r in claude.requests) r.channels.length], [20, 20, 5]);
      expect(claude.requests.first.channels.first['channel'], 'Channel 0');
      expect(results, hasLength(45));
      expect(results.values.map((c) => c.path).toSet(), {
        const CategoryPath('Knowledge'),
      });
    });

    test('a channel an answer leaves out is asked about alone', () async {
      final claude = ScriptedClaude(
        answer: (kind, channels) => [
          for (final channel in channels)
            if (channels.length == 1 || channel['channel'] != 'Channel 1')
              {
                'id': channel['id'],
                'parent': 'Music',
                'child': '',
                'emoji': '',
                'reason': '',
                'tags': const [],
              },
        ],
      );
      final pipeline = _withClaude(claude);

      final results = await ask(pipeline, await tickets(pipeline, 3));

      expect([for (final r in claude.requests) r.channels.length], [3, 1]);
      expect(claude.requests.last.channels.single['channel'], 'Channel 1');
      expect(results.keys, unorderedEquals(['UC0', 'UC1', 'UC2']));
    });

    test('an answer cut off is asked again in halves', () async {
      final claude = ScriptedClaude(
        answer: (kind, channels) {
          if (channels.length > 2) throw const AiNoAnswer();
          return [
            for (final channel in channels)
              {
                'id': channel['id'],
                'parent': 'Music',
                'child': '',
                'emoji': '',
                'reason': '',
                'tags': const [],
              },
          ];
        },
      );
      final pipeline = _withClaude(claude);

      final results = await ask(pipeline, await tickets(pipeline, 4));

      expect([for (final r in claude.requests) r.channels.length], [4, 2, 2]);
      expect(results, hasLength(4));
    });

    test('a request that takes too long is asked again in halves, not '
        'waited on', () async {
      final claude = ScriptedClaude(
        answer: (kind, channels) {
          if (channels.length > 2) throw const AiTimedOut();
          return [
            for (final channel in channels)
              {
                'id': channel['id'],
                'parent': 'Music',
                'child': '',
                'emoji': '',
                'reason': '',
                'tags': const [],
              },
          ];
        },
      );
      final pipeline = _withClaude(claude);

      final results = await ask(pipeline, await tickets(pipeline, 4));

      expect([for (final r in claude.requests) r.channels.length], [4, 2, 2]);
      expect(results, hasLength(4));
    });

    test(
      'a channel whose request takes too long keeps what YouTube gave',
      () async {
        final pipeline = _withClaude(_claude({}, failure: const AiTimedOut()));

        final category = await pipeline.categorize(
          _input(topics: [_topic('Video_game_culture')]),
        );

        expect(category.path, const CategoryPath('Gaming'));
      },
    );

    test('a channel with no usable answer keeps what YouTube gave, Claude '
        'counted as asked', () async {
      final pipeline = _withClaude(_claude({}, failure: const AiNoAnswer()));

      final category = await pipeline.categorize(
        _input(topics: [_topic('Video_game_culture')]),
      );

      expect(category.path, const CategoryPath('Gaming'));
      expect(category.prompts.keys, contains('claudeCategory'));
    });

    test('once stopped, are sent nothing', () async {
      final claude = _claude({'parent': 'Knowledge'});
      final pipeline = _withClaude(claude);

      final results = await ask(
        pipeline,
        await tickets(pipeline, 3),
        stopped: () => true,
      );

      expect(claude.requests, isEmpty);
      expect(results, isEmpty);
    });
  });

  test("a check asks Jev about the user's tags changed since the channel's "
      'last check, and nothing else', () async {
    final checkedAt = DateTime.utc(2026, 10, 5);
    final tags = TagIndex.of({
      'old': TagName(
        name: 'Old',
        origin: NameOrigin.user,
        meaning: 'Defined before',
        changedAt: checkedAt.subtract(const Duration(days: 1)),
      ),
      'new': TagName(
        name: 'New',
        origin: NameOrigin.user,
        meaning: 'Defined since',
        changedAt: checkedAt.add(const Duration(days: 1)),
      ),
    }, const {});
    final jev = _Jev(fits: {'New': 0.9});

    final checked = await _pipeline(jev).prepare(
      _input(),
      (work: ChannelWork.none, redo: false, checkTags: true),
      existing: ChannelCategory(tagsCheckedAt: checkedAt, decidedAt: checkedAt),
      tags: tags,
    );

    expect(checked, isA<Checked>().having((c) => c.yes, 'yes', {'new': 0.9}));
    expect(jev.requests.single.keys, ['tag_0']);
  });
}
