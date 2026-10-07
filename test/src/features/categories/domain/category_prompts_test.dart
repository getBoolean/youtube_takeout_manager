import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_prompts.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';

final _taxonomy = youtubeTaxonomy.withCustom({
  'Gaming': ['Speedruns'],
});

const _evidence = ChannelEvidence(
  title: 'Speedy',
  titles: ['Any% in 10 minutes'],
);

void main() {
  test('Claude is told every category, with the sub-categories there are, '
      'to reuse one that fits', () {
    final request = claudeCategoryGroupRequest([
      (
        id: 'c1',
        evidence: _evidence,
        category: null,
        keptTags: const <String>[],
        inaccurate: null,
      ),
    ], _taxonomy);

    expect(request.system, contains('Speedruns'));
    expect(request.system, contains('Knowledge'));
    expect(request.user, contains('Any% in 10 minutes'));
  });

  group("Claude's answer", () {
    test('names a category and sub-category that exist, however cased', () {
      final suggestion = parseClaudeSuggestion({
        'parent': 'Gaming',
        'child': 'speedruns',
        'reason': 'Races through games',
      }, _taxonomy);

      expect(suggestion?.parent, 'Gaming');
      expect(suggestion?.child, 'speedruns');
      expect(suggestion?.reason, 'Races through games');
    });

    test('without a sub-category is the category alone', () {
      final suggestion = parseClaudeSuggestion({
        'parent': 'Knowledge',
        'child': null,
        'reason': 'Explains science',
      }, _taxonomy);

      expect(suggestion?.child, isNull);
    });

    test('with a sub-category that is not text is the category alone', () {
      final suggestion = parseClaudeSuggestion({
        'parent': 'Knowledge',
        'child': 42,
        'reason': 'Explains science',
      }, _taxonomy);

      expect(suggestion?.parent, 'Knowledge');
      expect(suggestion?.child, isNull);
    });

    test('naming a category that does not exist is no answer', () {
      expect(
        parseClaudeSuggestion({
          'parent': 'Cooking',
          'child': 'Baking',
          'reason': '',
        }, _taxonomy),
        isNull,
      );
    });
  });

  group("Claude's tags", () {
    test('are tidied, each once, at most five, leaving out what is not a '
        'tag', () {
      final suggestion = parseClaudeSuggestion({
        'parent': 'Gaming',
        'child': 'Speed running',
        'emoji': 'Speedy',
        'tags': [
          'Mario-Kart',
          'mario kart',
          '',
          '  Blue   Archive ',
          'x' * 60,
          7,
          'C',
          'D',
          'E',
        ],
        'reason': 'Races',
      }, _taxonomy);

      expect(
        [for (final tag in suggestion!.tags) tag.name],
        ['Mario-Kart', 'Blue Archive', 'x' * maxTagName, 'C', 'D'],
      );
      expect(suggestion.emoji, isNull);
    });

    test('none, or not a list, are none', () {
      expect(parseNamedTags(null), isEmpty);
      expect(parseNamedTags('ASMR'), isEmpty);
    });
  });

  group('a request about several channels', () {
    final items = [
      (
        id: 'c1',
        evidence: _evidence,
        category: null,
        keptTags: const <String>[],
        inaccurate: null,
      ),
      (
        id: 'c2',
        evidence: const ChannelEvidence(
          title: 'Jelly Ch.',
          titles: ['Singing and Minecraft'],
        ),
        category: const CategoryPath('Entertainment'),
        keptTags: const ['VTuber', 'Music'],
        inaccurate: const CategoryPath('Music'),
      ),
    ];
    const known = [
      (name: 'Phase Connect', meaning: 'A VTuber agency'),
      (name: 'ASMR', meaning: null),
    ];
    final requests = {
      'category and tags': claudeCategoryGroupRequest(
        items,
        _taxonomy,
        knownTags: known,
      ),
      'tags only': claudeTagsGroupRequest(items, knownTags: known),
    };

    Map<String, Object?> item(ClaudeRequest request) =>
        ((request.schema['properties']! as Map)['answers']! as Map)['items']!
            as Map<String, Object?>;

    test('answers each channel by an id the request gives, c1 to cN', () {
      for (final MapEntry(key: name, value: request) in requests.entries) {
        final id = (item(request)['properties']! as Map)['id'] as Map;
        expect(id['enum'], ['c1', 'c2'], reason: name);
        final channels = (jsonDecode(request.user) as Map)['channels'] as List;
        expect([for (final c in channels) (c as Map)['id']], ['c1', 'c2']);
      }
    });

    test('takes only the answer it asks for, all of it, in a shape Claude '
        'can take', () {
      void walk(Object? node, String name) {
        if (node is Map) {
          expect(node.containsKey('anyOf'), isFalse, reason: name);
          expect(node.containsKey('maxItems'), isFalse, reason: name);
          if (node['type'] == 'object') {
            expect(node['additionalProperties'], isFalse, reason: name);
            expect(
              (node['required']! as List).toSet(),
              (node['properties']! as Map).keys.toSet(),
              reason: name,
            );
          }
          for (final value in node.values) {
            walk(value, name);
          }
        } else if (node is List) {
          for (final value in node) {
            walk(value, name);
          }
        }
      }

      for (final MapEntry(key: name, value: request) in requests.entries) {
        walk(request.schema, name);
      }
      final parent =
          (item(requests['category and tags']!)['properties']! as Map)['parent']
              as Map;
      expect(parent['enum'], _taxonomy.parents.toList());
    });

    test("tells Claude the tags there are, the user's with their meanings, "
        "and each channel's tags found, category and note", () {
      for (final MapEntry(key: name, value: request) in requests.entries) {
        expect(request.system, contains('Phase Connect'), reason: name);
        expect(request.system, contains('A VTuber agency'), reason: name);
        expect(request.system, contains('ASMR'), reason: name);
        final channels = (jsonDecode(request.user) as Map)['channels'] as List;
        final jelly = channels[1] as Map;
        expect(jelly['tags_found'], ['VTuber', 'Music'], reason: name);
        expect(jelly['watched_video_titles'], ['Singing and Minecraft']);
        expect(jelly.containsKey('tags_found'), isTrue);
        expect((channels[0] as Map).containsKey('tags_found'), isFalse);
      }
      final tagsOnly = jsonDecode(requests['tags only']!.user) as Map;
      expect(
        ((tagsOnly['channels'] as List)[1] as Map)['category'],
        'Entertainment',
      );
      final categories = jsonDecode(requests['category and tags']!.user) as Map;
      expect(
        ((categories['channels'] as List)[1] as Map)['note'],
        contains('Music'),
      );
    });

    group("and Claude's answer to it", () {
      test('is each id once, its first answer, leaving out ids not asked '
          'about', () {
        final answers = parseClaudeGroup(
          {
            'answers': [
              {
                'id': 'c2',
                'parent': 'Entertainment',
                'child': '',
                'emoji': '',
                'tags': [
                  {'name': 'Phase Connect', 'meaning': ''},
                ],
                'reason': 'Sings and plays',
              },
              {
                'id': 'c2',
                'parent': 'Music',
                'child': '',
                'emoji': '',
                'tags': [],
                'reason': 'Second answer',
              },
              {
                'id': 'c9',
                'parent': 'Gaming',
                'child': '',
                'emoji': '',
                'tags': [],
                'reason': 'Not asked',
              },
            ],
          },
          {'c1', 'c2'},
          _taxonomy,
        );

        expect(answers.keys, ['c2']);
        expect(answers['c2']?.parent, 'Entertainment');
        expect(answers['c2']?.child, isNull);
        expect(answers['c2']?.emoji, isNull);
        expect(answers['c2']?.tags, [(name: 'Phase Connect', meaning: null)]);
      });

      test("keeps a new tag's meaning, cut short when long", () {
        final answers = parseClaudeTagsGroup(
          {
            'answers': [
              {
                'id': 'c1',
                'tags': [
                  {'name': 'Mario Kart 8 Deluxe', 'meaning': 'x' * 300},
                ],
              },
            ],
          },
          {'c1'},
          const {'c1': maxTags},
        );

        expect(answers['c1']?.single.meaning, hasLength(maxTagMeaning));
      });

      test('gives a channel only the tags it has room for', () {
        final answers = parseClaudeTagsGroup(
          {
            'answers': [
              {
                'id': 'c2',
                'tags': [
                  for (final name in ['A', 'B', 'C', 'D'])
                    {'name': name, 'meaning': ''},
                ],
              },
            ],
          },
          {'c2'},
          const {'c2': 3},
        );

        expect([for (final t in answers['c2']!) t.name], ['A', 'B', 'C']);
      });

      test('keeps at most 5 clean, distinct tags for each channel, and no '
          'emoji that is a word', () {
        final answers = parseClaudeGroup(
          {
            'answers': [
              {
                'id': 'c1',
                'parent': 'Gaming',
                'child': 'Speed running',
                'emoji': 'Speedy',
                'tags': [
                  for (final name in [
                    'Mario-Kart',
                    'mario kart',
                    '',
                    '  Blue   Archive ',
                    'x' * 60,
                    'C',
                    'D',
                    'E',
                  ])
                    {'name': name, 'meaning': ''},
                ],
                'reason': 'Races',
              },
            ],
          },
          {'c1'},
          _taxonomy,
        );

        expect(
          [for (final t in answers['c1']!.tags) t.name],
          ['Mario-Kart', 'Blue Archive', 'x' * maxTagName, 'C', 'D'],
        );
        expect(answers['c1']?.emoji, isNull);
      });
    });
  });

  test('channels are packed into requests in order, at most 20 and so '
      'much text each, a big one alone', () {
    final sizes = [...List.filled(25, 100), 50000, ...List.filled(3, 15000)];

    final groups = packGroups([
      for (final (i, s) in sizes.indexed) (i, s),
    ], (item) => item.$2);

    expect([for (final g in groups) g.length], [20, 5, 1, 2, 1]);
    expect(
      [for (final g in groups) ...g.map((item) => item.$1)],
      [for (var i = 0; i < sizes.length; i++) i],
    );
  });

  test("a request's answer may be as long as its channels need, up to what "
      'the model gives', () {
    expect(
      groupAnswerTokens(20, withCategory: true),
      greaterThan(groupAnswerTokens(20, withCategory: false)),
    );
    expect(
      groupAnswerTokens(20, withCategory: true),
      greaterThan(groupAnswerTokens(1, withCategory: true)),
    );
    expect(groupAnswerTokens(20, withCategory: true, modelMax: 1000), 1000);
  });

  test('an emoji Claude gives for a new sub-category is kept', () {
    expect(parseEmoji('🏃'), '🏃');
    expect(parseEmoji(' 🏎️ '), '🏎️');
    expect(parseEmoji('Run'), isNull);
    expect(parseEmoji(''), isNull);
    expect(parseEmoji(3), isNull);
  });

  group('a new sub-category name', () {
    test('is trimmed, with single spaces', () {
      expect(
        normalizeChildName('  Retro   game  speedruns '),
        'Retro game speedruns',
      );
    });

    test('is cut short when long', () {
      expect(normalizeChildName('x' * 100)!.length, maxChildName);
    });

    test('blank is none', () {
      expect(normalizeChildName('   '), isNull);
      expect(normalizeChildName(null), isNull);
    });
  });
}
