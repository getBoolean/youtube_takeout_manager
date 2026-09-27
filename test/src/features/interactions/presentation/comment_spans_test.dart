import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_key.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/comment_spans.dart';

void main() {
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
}
