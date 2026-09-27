import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_shortcode.dart';

void main() {
  group('emojiFragmentAtEnd', () {
    test('finds the :name being typed', () {
      expect(emojiFragmentAtEnd('lol :Sho'), (
        start: 4,
        end: 8,
        name: 'sho',
        channelOnly: false,
      ));
      expect(emojiFragmentAtEnd(':fire-x'), (
        start: 0,
        end: 7,
        name: 'fire-x',
        channelOnly: false,
      ));
    });

    test(':_name is only for channel emojis', () {
      expect(emojiFragmentAtEnd('hi :_sh'), (
        start: 3,
        end: 7,
        name: 'sh',
        channelOnly: true,
      ));
    });

    test('needs two characters', () {
      expect(emojiFragmentAtEnd(':s'), isNull);
      expect(emojiFragmentAtEnd('hi :-'), isNull);
    });

    test('a time or word:name is not an emoji name', () {
      expect(emojiFragmentAtEnd('at 10:30'), isNull);
      expect(emojiFragmentAtEnd('word:sh'), isNull);
    });

    test('only at the end', () {
      expect(emojiFragmentAtEnd(':fire '), isNull);
      expect(emojiFragmentAtEnd(':fire:'), isNull);
    });
  });

  group('closedEmojiName', () {
    ({int start, String name})? closing(String text) =>
        closedEmojiName(text, text.length);

    test('finds the :name: a typed colon closes', () {
      expect(closing('hi :Fire:'), (start: 3, name: 'fire'));
      expect(closing(':thumbs-up:'), (start: 0, name: 'thumbs-up'));
    });

    test('leaves other colons alone', () {
      for (final text in ['::', 'x:fire:', '10:30:', 'fire:', ':a b:']) {
        expect(closing(text), isNull, reason: text);
      }
    });

    test('keeps the underscore of :_name:', () {
      expect(closing(':_fire:'), (start: 0, name: '_fire'));
    });
  });

  test('emojiTokensIn finds complete :name: and :_name: tokens', () {
    expect(emojiTokensIn('a :shortsad: :_Wave: 10:30 :x'), [
      (start: 2, end: 12, name: 'shortsad'),
      (start: 13, end: 20, name: 'Wave'),
    ]);
  });

  test('isValidEmojiName', () {
    expect(isValidEmojiName('short-sad_2'), isTrue);
    expect(isValidEmojiName('a b'), isFalse);
    expect(isValidEmojiName(''), isFalse);
    expect(isValidEmojiName('x' * 65), isFalse);
  });

  group('queryMentionsEmoji', () {
    test('only for :name tokens', () {
      expect(queryMentionsEmoji('short'), isFalse);
      expect(queryMentionsEmoji('a: b'), isFalse);
      expect(queryMentionsEmoji(':short'), isTrue);
      expect(queryMentionsEmoji('gg :shortsad:'), isTrue);
    });
  });

  group('emojiMatchesQuery', () {
    test('matches names containing a :token', () {
      expect(emojiMatchesQuery('shortcatTiger', ':short'), isTrue);
      expect(emojiMatchesQuery('shortcatTiger', 'gg :SHORTCAT'), isTrue);
      expect(emojiMatchesQuery('shortcatTiger', ':_short'), isTrue);
      expect(emojiMatchesQuery('shortsad', ':shortsad:'), isTrue);
    });

    test('ignores plain words and other names', () {
      expect(emojiMatchesQuery('shortcatTiger', 'short'), isFalse);
      expect(emojiMatchesQuery('shortsadder', ':shortsad:'), isFalse);
      expect(emojiMatchesQuery('cat', ':short'), isFalse);
    });
  });

  group('normalizeEmojiQuery', () {
    test('strips YouTube underscore prefix inside tokens', () {
      expect(
        normalizeEmojiQuery('hi :_shortsad: :other:'),
        'hi :shortsad: :other:',
      );
    });

    test('strips it from a token still being typed', () {
      expect(normalizeEmojiQuery('hi :_sho'), 'hi :sho');
    });

    test('leaves plain text alone', () {
      expect(
        normalizeEmojiQuery('snake_case :_ partial'),
        'snake_case :_ partial',
      );
    });
  });
}
