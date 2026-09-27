import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_key.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/searchable_comment_text.dart';

const _key =
    'nqCqL7OuHfRl5bstpirPEbLuD9ldK6pyPVVzCWLjjAWk3lN5EMwErHNozzjGajgr0f3hQ0TXfA';
const _raw =
    '{"text":"not the reds again "},'
    '{"text":"","emoji":{"customEmojiUrl":"https://yt3.googleusercontent.com/$_key"}}';

void main() {
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
    });

    test('leaves emoji names out for plain-text searches', () {
      final text = searchableCommentText(_raw, {
        _key: 'shortsad',
      }, emojiNames: false);
      expect(text, startsWith('not the reds again '));
      expect(text, isNot(contains('short')));
    });
  });
}
