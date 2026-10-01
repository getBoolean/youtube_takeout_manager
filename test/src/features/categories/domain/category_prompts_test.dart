import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_prompts.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
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
    final request = claudeCategoryRequest(_evidence, _taxonomy);

    expect(request.system, contains('Speedruns'));
    expect(request.system, contains('Knowledge'));
    expect(request.user, contains('Any% in 10 minutes'));
    final parent =
        (request.schema['properties']! as Map)['parent']
            as Map<String, Object?>;
    expect(parent['enum'], _taxonomy.parents.toList());
    expect(request.schema['additionalProperties'], isFalse);
  });

  test('asked again, Claude is told the category it had is wrong', () {
    final request = claudeCategoryRequest(
      _evidence,
      _taxonomy,
      inaccurate: const CategoryPath('Gaming', 'Action'),
    );

    expect(request.user, contains('Gaming › Action'));
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

  group('every request to Claude', () {
    final requests = {
      'category and tags': claudeCategoryRequest(
        _evidence,
        _taxonomy,
        knownTags: const ['Blue Archive', 'ASMR'],
      ),
      'tags only': claudeTagsRequest(
        _evidence,
        const CategoryPath('Gaming', 'Speedruns'),
        knownTags: const ['Blue Archive', 'ASMR'],
      ),
    };

    test('takes only the answer it asks for, all of it', () {
      for (final MapEntry(key: name, value: request) in requests.entries) {
        final properties = request.schema['properties']! as Map;
        expect(request.schema['additionalProperties'], isFalse, reason: name);
        expect(
          (request.schema['required']! as List).toSet(),
          properties.keys.toSet(),
          reason: name,
        );
        expect(properties.keys, contains('tags'), reason: name);
      }
    });

    test('names the tags there are, to reuse', () {
      for (final MapEntry(key: name, value: request) in requests.entries) {
        expect(request.system, contains('Blue Archive'), reason: name);
        expect(request.system, contains('ASMR'), reason: name);
      }
    });

    test('for tags alone, gives the category', () {
      expect(requests['tags only']!.user, contains('Gaming › Speedruns'));
      expect(requests['tags only']!.user, contains('Any% in 10 minutes'));
    });

    test('for a category, asks for an emoji for a new sub-category', () {
      final properties =
          requests['category and tags']!.schema['properties']! as Map;
      expect(properties.keys, contains('emoji'));
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

      expect(suggestion?.tags, [
        'Mario-Kart',
        'Blue Archive',
        'x' * maxTagName,
        'C',
        'D',
      ]);
      expect(suggestion?.emoji, isNull);
    });

    test('none, or not a list, are none', () {
      expect(parseClaudeTags(null), isEmpty);
      expect(parseClaudeTags('ASMR'), isEmpty);
    });
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
