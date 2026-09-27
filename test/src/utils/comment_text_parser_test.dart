import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_key.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';

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

  test('buildCommentSpans tells each emoji its adjacent emojis', () {
    String emoji(String key) =>
        '{"text":"","emoji":{"customEmojiUrl":"https://yt3.ggpht.com/$key"}}';
    final calls = <String, AdjacentEmojis>{};
    buildCommentSpans(
      '{"text":"a "},${emoji('k1')},${emoji('k2')},{"text":" b "},${emoji('k3')}',
      emojiSize: 20,
      emojiBuilder: (url, size, adjacent) {
        calls[emojiKey(url)] = adjacent;
        return const SizedBox();
      },
    );
    expect(calls, {
      'k1': (previousUrl: null, nextUrl: 'https://yt3.ggpht.com/k2'),
      'k2': (previousUrl: 'https://yt3.ggpht.com/k1', nextUrl: null),
      'k3': (previousUrl: null, nextUrl: null),
    });
  });

  group('foldForSearch', () {
    test('lowercases and drops the emoji presentation selector', () {
      expect(foldForSearch('Love ❤️ It'), 'love ❤ it');
    });

    test('keeps skin tones and ZWJ sequences', () {
      const thumbsUpMedium = '\u{1F44D}\u{1F3FD}';
      const technologist = '\u{1F9D1}‍\u{1F4BB}';
      expect(foldForSearch(thumbsUpMedium), thumbsUpMedium);
      expect(foldForSearch(technologist), technologist);
    });
  });
}
