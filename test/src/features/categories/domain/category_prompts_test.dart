import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_prompts.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';

final _taxonomy = youtubeTaxonomy.withCustom({
  'Gaming': ['Speedruns'],
});

const _evidence = ChannelEvidence(
  title: 'Speedy',
  recentTitles: ['Any% in 10 minutes'],
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
