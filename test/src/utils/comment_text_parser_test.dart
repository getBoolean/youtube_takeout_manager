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
  });

  group('normalizeEmojiQuery', () {
    test('strips YouTube underscore prefix inside tokens', () {
      expect(
        normalizeEmojiQuery('hi :_shortsad: :other:'),
        'hi :shortsad: :other:',
      );
    });

    test('leaves plain text alone', () {
      expect(
        normalizeEmojiQuery('snake_case :_ partial'),
        'snake_case :_ partial',
      );
    });
  });
}
