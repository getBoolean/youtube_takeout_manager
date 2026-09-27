import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_key.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_shortcode.dart';

const _key =
    'nqCqL7OuHfRl5bstpirPEbLuD9ldK6pyPVVzCWLjjAWk3lN5EMwErHNozzjGajgr0f3hQ0TXfA';

void main() {
  test('emojiKey matches between Takeout and live chat URLs', () {
    expect(emojiKey('https://yt3.googleusercontent.com/$_key'), _key);
    expect(emojiKey('https://yt3.ggpht.com/$_key=w24-h24-c-k-nd'), _key);
  });

  test('fallbackEmojiName gives a usable name, stable per key', () {
    const other =
        'AKeDLQwYpVRbMFwsH-9ppKmXGLNoKGqBzRPB8o2hk8-sZrLdTCPEWxfE-yTJeFk_7sw';
    for (final key in [_key, other, 'k1']) {
      final name = fallbackEmojiName(key);
      expect(name, startsWith('emoji_'));
      expect(isValidEmojiName(name), isTrue, reason: name);
      expect(fallbackEmojiName(key), name);
    }
    expect(fallbackEmojiName(_key), isNot(fallbackEmojiName(other)));
  });

  test('isEmojiImageUrl rejects what Takeout writes for missing emojis', () {
    expect(isEmojiImageUrl('https://yt3.ggpht.com/$_key'), isTrue);
    expect(isEmojiImageUrl('Failed to get emoji URL'), isFalse);
    expect(isEmojiImageUrl(''), isFalse);
  });
}
