import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';

void main() {
  group('finding a sub-category', () {
    test('matches it whatever its hyphens, spaces or case', () {
      expect(
        youtubeTaxonomy.find('music', 'Hip-Hop'),
        const CategoryPath('Music', 'Hip hop'),
      );
      expect(
        youtubeTaxonomy.find('Gaming', 'role playing'),
        const CategoryPath('Gaming', 'Role-playing'),
      );
    });

    test('finds nothing for a name that is not there', () {
      expect(youtubeTaxonomy.find('Music', 'Shoegaze'), isNull);
      expect(youtubeTaxonomy.find('Cooking'), isNull);
    });
  });

  test('a path is there only as it is spelled there', () {
    expect(
      youtubeTaxonomy.contains(const CategoryPath('Music', 'Hip hop')),
      isTrue,
    );
    expect(
      youtubeTaxonomy.contains(const CategoryPath('Music', 'Hip-hop')),
      isFalse,
    );
  });

  group('with sub-categories added', () {
    test("YouTube's spelling is kept over a variant of it", () {
      final taxonomy = youtubeTaxonomy.withCustom({
        'Music': ['Hip-hop', 'Shoegaze'],
      });

      expect(taxonomy.childrenOf('Music'), contains('Hip hop'));
      expect(taxonomy.childrenOf('Music'), isNot(contains('Hip-hop')));
      expect(taxonomy.childrenOf('Music'), contains('Shoegaze'));
    });

    test('variants of an added one are kept once, as first spelled', () {
      final taxonomy = youtubeTaxonomy.withCustom({
        'Gaming': ['Speed-runs', 'Speedruns', 'speed runs'],
      });

      final speedruns = taxonomy
          .childrenOf('Gaming')
          .where((child) => child.toLowerCase().startsWith('speed'));
      expect(speedruns, ['Speed-runs']);
    });
  });
}
