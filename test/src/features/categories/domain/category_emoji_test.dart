import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_emoji.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';

void main() {
  test("every one of YouTube's categories and sub-categories has an emoji", () {
    for (final parent in youtubeTaxonomy.parents) {
      expect(categoryEmoji[parent], isNotNull, reason: parent);
      for (final child in youtubeTaxonomy.childrenOf(parent)) {
        expect(
          youtubeSubCategoryEmoji[parent]?[child],
          isNotNull,
          reason: '$parent › $child',
        );
        expect(
          emojiOf(CategoryPath(parent, child)),
          youtubeSubCategoryEmoji[parent]![child],
        );
      }
    }
  });

  test('a category without a sub-category shows its own emoji', () {
    expect(emojiOf(const CategoryPath('Music')), categoryEmoji['Music']);
  });

  test('a channel with no category shows the uncategorized one', () {
    expect(emojiOf(null), uncategorizedEmoji);
  });

  test('a sub-category made for channels shows its own emoji, else its '
      "category's", () {
    const custom = {
      'Gaming': [
        SubCategory(name: 'Retro', emoji: '👾'),
        SubCategory(name: 'Speedruns'),
      ],
    };

    expect(
      emojiOf(const CategoryPath('Gaming', 'retro'), custom: custom),
      '👾',
    );
    expect(
      emojiOf(const CategoryPath('Gaming', 'Speedruns'), custom: custom),
      categoryEmoji['Gaming'],
    );
    expect(
      emojiOf(const CategoryPath('Gaming', 'Unknown'), custom: custom),
      categoryEmoji['Gaming'],
    );
  });
}
