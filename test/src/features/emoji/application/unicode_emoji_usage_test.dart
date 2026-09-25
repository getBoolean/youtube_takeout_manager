import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/unicode_emoji.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';

const _fire = '\u{1F525}';
const _grinning = '\u{1F600}';
const _thumbsUpMedium = '\u{1F44D}\u{1F3FD}';

Comment _comment(String channelId, String raw) => Comment(
  commentId: raw,
  channelId: channelId,
  createdAt: DateTime(2024),
  price: 0,
  rawCommentText: raw,
  displayText: raw,
);

LiveChat _chat(String channelId, String raw) => LiveChat(
  liveChatId: raw,
  channelId: channelId,
  createdAt: DateTime(2024),
  price: 0,
  rawText: raw,
  displayText: raw,
);

void main() {
  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [
        commentsByChannelProvider.overrideWithValue({
          'a': [
            _comment('a', '{"text":"so lit $_fire$_fire"}'),
            _comment('a', '{"text":"plain text only"}'),
          ],
        }),
        liveChatsByChannelProvider.overrideWithValue({
          'a': [_chat('a', '{"text":"nice $_thumbsUpMedium"}')],
          'b': [
            _chat('b', '{"text":"hi $_grinning"}'),
            // A channel emoji isn't a standard one.
            _chat(
              'b',
              '{"text":"","emoji":{"customEmojiUrl":"https://yt3.ggpht.com/k"}}',
            ),
          ],
        }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  List<String> names(List<UnicodeEmoji> emojis) => [
    for (final emoji in emojis) emoji.shortName,
  ];

  test('lists the standard emojis used in a channel, in picker order', () {
    final c = container();
    expect(names(c.read(channelUnicodeEmojisProvider('a'))), [
      'thumbsup',
      'fire',
    ]);
    expect(names(c.read(channelUnicodeEmojisProvider('b'))), ['grinning']);
    expect(c.read(channelUnicodeEmojisProvider('none')), isEmpty);
  });

  test('lists the standard emojis used anywhere', () {
    expect(names(container().read(allUsedUnicodeEmojisProvider)), [
      'grinning',
      'thumbsup',
      'fire',
    ]);
  });
}
