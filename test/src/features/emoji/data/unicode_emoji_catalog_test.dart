import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/data/unicode_emoji_catalog.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/unicode_emoji.dart';

void main() {
  test('parses rows', () {
    final catalog = UnicodeEmojiCatalog({
      UnicodeEmojiCategory.nature: ['\u{1F525}\tfire flame\tfire'],
    });
    final fire = catalog.byShortName['flame']!;
    expect(fire.emoji, '\u{1F525}');
    expect(fire.shortNames, ['fire', 'flame']);
    expect(fire.token, ':fire:');
    expect(fire.name, 'fire');
    expect(fire.category, UnicodeEmojiCategory.nature);
    expect(catalog.byShortName['fire'], same(fire));
    expect(catalog.byEmoji['\u{1F525}'], same(fire));
    expect(catalog.byCategory[UnicodeEmojiCategory.nature], [fire]);
  });

  test('find matches what a search would', () {
    final catalog = unicodeEmojiCatalog;
    expect(catalog.find('\u{1F525}')?.shortName, 'fire');
    // With or without the emoji presentation selector.
    expect(catalog.find('❤')?.shortName, 'heart');
    expect(catalog.find('❤️')?.shortName, 'heart');
    // A search for 👍 finds 👍🏽.
    expect(catalog.find('\u{1F44D}\u{1F3FD}')?.shortName, 'thumbsup');
    // But one for 🧑‍💻 doesn't find 🧑🏽‍💻.
    expect(catalog.find('\u{1F9D1}\u{1F3FD}‍\u{1F4BB}'), isNull);
    expect(catalog.find('a'), isNull);
  });

  group('generated data', () {
    final catalog = unicodeEmojiCatalog;
    UnicodeEmojiCategory? categoryOf(String name) =>
        catalog.byShortName[name]?.category;

    test('has the names people type', () {
      expect(catalog.byShortName['fire']?.emoji, '\u{1F525}');
      expect(catalog.byShortName['red_circle']?.emoji, '\u{1F534}');
      expect(catalog.byShortName['thumbsup'], isNotNull);
      expect(catalog.byShortName['+1'], isNull);
    });

    test('includes Emoji 15.1 and 16.0', () {
      expect(catalog.byShortName['phoenix'], isNotNull);
      expect(catalog.byShortName['harp'], isNotNull);
    });

    test('leaves out the skin tone swatches', () {
      expect(catalog.byShortName['skin-tone-2'], isNull);
      expect(catalog.byEmoji['\u{1F3FB}'], isNull);
    });

    test('uses Discord categories in Discord order', () {
      expect(catalog.byCategory.keys, UnicodeEmojiCategory.values);
      expect(
        catalog.byCategory[UnicodeEmojiCategory.people]!.first.shortName,
        'grinning',
      );
      expect(categoryOf('wave'), UnicodeEmojiCategory.people);
      expect(categoryOf('kiss'), UnicodeEmojiCategory.people);
      expect(categoryOf('heart'), UnicodeEmojiCategory.symbols);
      expect(categoryOf('100'), UnicodeEmojiCategory.symbols);
      expect(categoryOf('fire'), UnicodeEmojiCategory.nature);
      expect(categoryOf('sunny'), UnicodeEmojiCategory.nature);
      expect(categoryOf('airplane'), UnicodeEmojiCategory.travel);
    });

    test('every category has emojis and every name is typeable', () {
      final plainName = RegExp(r'^[\w-]+$');
      for (final emojis in catalog.byCategory.values) {
        expect(emojis, isNotEmpty);
      }
      for (final emoji in catalog.all) {
        for (final name in emoji.shortNames) {
          expect(name, matches(plainName));
        }
      }
    });
  });
}
