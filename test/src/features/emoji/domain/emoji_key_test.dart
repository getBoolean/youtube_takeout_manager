import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_key.dart';

const _key =
    'nqCqL7OuHfRl5bstpirPEbLuD9ldK6pyPVVzCWLjjAWk3lN5EMwErHNozzjGajgr0f3hQ0TXfA';

void main() {
  test('emojiKey matches between Takeout and live chat URLs', () {
    expect(emojiKey('https://yt3.googleusercontent.com/$_key'), _key);
    expect(emojiKey('https://yt3.ggpht.com/$_key=w24-h24-c-k-nd'), _key);
  });

  test('fallbackEmojiName uses the start of the key', () {
    expect(fallbackEmojiName(_key), 'emoji_nqCqL7');
    expect(fallbackEmojiName('k1'), 'emoji_k1');
  });

  test('isEmojiImageUrl rejects what Takeout writes for missing emojis', () {
    expect(isEmojiImageUrl('https://yt3.ggpht.com/$_key'), isTrue);
    expect(isEmojiImageUrl('Failed to get emoji URL'), isFalse);
    expect(isEmojiImageUrl(''), isFalse);
  });
}
