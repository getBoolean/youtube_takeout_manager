import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_topics.dart';

String _url(String slug) => 'https://en.wikipedia.org/wiki/$slug';

void main() {
  test("YouTube's topics map to its categories and sub-categories", () {
    expect(
      categoryOfTopic(_url('Video_game_culture')),
      const CategoryPath('Gaming'),
    );
    expect(
      categoryOfTopic(_url('Action_game')),
      const CategoryPath('Gaming', 'Action'),
    );
    expect(
      categoryOfTopic(_url('Hip_hop_music')),
      const CategoryPath('Music', 'Hip hop'),
    );
    expect(
      categoryOfTopic(_url('Lifestyle_(sociology)')),
      const CategoryPath('Lifestyle'),
    );
    expect(
      categoryOfTopic(
        'https://en.wikipedia.org/wiki/Lifestyle_%28sociology%29',
      ),
      const CategoryPath('Lifestyle'),
    );
  });

  test('every topic maps into the categories', () {
    for (final path in youtubeTopicCategories.values) {
      expect(youtubeTaxonomy.contains(path), isTrue, reason: path.label);
    }
  });

  test('an unknown topic maps to nothing', () {
    expect(categoryOfTopic(_url('Quantum_basket_weaving')), isNull);
    expect(categoryOfTopic('not a link'), isNull);
  });

  test(
    "a channel's candidates are its sub-categories, else its categories",
    () {
      expect(
        youtubeCandidates([
          _url('Video_game_culture'),
          _url('Action_game'),
          _url('Role-playing_video_game'),
        ]),
        const [
          CategoryPath('Gaming', 'Action'),
          CategoryPath('Gaming', 'Role-playing'),
        ],
      );
      expect(youtubeCandidates([_url('Knowledge'), _url('Society')]), const [
        CategoryPath('Knowledge'),
        CategoryPath('Society'),
      ]);
      expect(youtubeCandidates(const []), isEmpty);
    },
  );

  test('a topic reads as its name', () {
    expect(
      topicLabel(_url('Role-playing_video_game')),
      'Role-playing video game',
    );
  });

  group('the categories', () {
    test('name a sub-category after its category', () {
      expect(const CategoryPath('Gaming', 'Action').label, 'Gaming › Action');
      expect(const CategoryPath('Knowledge').label, 'Knowledge');
    });

    test('take sub-categories AI made, once each whatever their case', () {
      final taxonomy = youtubeTaxonomy.withCustom({
        'Gaming': ['Speedruns', 'action'],
      });

      expect(taxonomy.childrenOf('Gaming'), contains('Speedruns'));
      expect(
        taxonomy.childrenOf('Gaming').where((c) => c.toLowerCase() == 'action'),
        hasLength(1),
      );
      expect(
        taxonomy.contains(const CategoryPath('Gaming', 'Speedruns')),
        isTrue,
      );
    });

    test('a sub-category is found whatever its case', () {
      expect(
        youtubeTaxonomy.find('gaming', 'ACTION'),
        const CategoryPath('Gaming', 'Action'),
      );
      expect(youtubeTaxonomy.find('Gaming', 'Speedruns'), isNull);
    });
  });

  test('a category path is kept and read back the same', () {
    for (final path in const [
      CategoryPath('Gaming', 'Action'),
      CategoryPath('Knowledge'),
    ]) {
      expect(CategoryPathMapper.fromJson(path.toJson()), path);
    }
  });
}
