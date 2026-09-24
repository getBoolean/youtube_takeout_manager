import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';

const _key =
    'nqCqL7OuHfRl5bstpirPEbLuD9ldK6pyPVVzCWLjjAWk3lN5EMwErHNozzjGajgr0f3hQ0TXfA';
const _raw =
    '{"text":"not the reds again "},'
    '{"text":"","emoji":{"customEmojiUrl":"https://yt3.googleusercontent.com/$_key"}}';

void main() {
  group('emojiKey', () {
    test('matches between Takeout and live chat URLs', () {
      expect(emojiKey('https://yt3.googleusercontent.com/$_key'), _key);
      expect(emojiKey('https://yt3.ggpht.com/$_key=w24-h24-c-k-nd'), _key);
    });
  });

  group('searchableCommentText', () {
    test('writes resolved emojis as :name:', () {
      expect(
        searchableCommentText(_raw, {_key: 'shortsad'}),
        'not the reds again :shortsad:',
      );
    });

    test('falls back to a generated name', () {
      expect(
        searchableCommentText(_raw, const {}),
        'not the reds again :${fallbackEmojiName(_key)}:',
      );
      expect(fallbackEmojiName(_key), 'emoji_nqCqL7');
    });

    test('leaves emoji names out for plain-text searches', () {
      final text = searchableCommentText(_raw, {
        _key: 'shortsad',
      }, emojiNames: false);
      expect(text, startsWith('not the reds again '));
      expect(text, isNot(contains('short')));
    });
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
