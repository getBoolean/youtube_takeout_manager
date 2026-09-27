import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_names.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/channel_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_key.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';

String _emoji(String key) =>
    '{"text":"","emoji":{"customEmojiUrl":"https://yt3.ggpht.com/$key"}}';

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

Channel _channel(String id, String title, [String? thumbnailUrl]) => Channel(
  channelId: id,
  channelTitle: title,
  thumbnailUrl: thumbnailUrl,
  commentCount: 1,
  liveChatCount: 1,
);

final _channels = [
  _channel('b', 'Bee', 'bee'),
  _channel('c', 'Sea'),
  _channel('a', 'Ay'),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container({Map<String, String> names = const {}}) {
    final container = ProviderContainer(
      overrides: [
        interactionsByChannelProvider(QueueItemKind.comment).overrideWithValue({
          'a': [
            _comment('a', '{"text":"hi "},${_emoji('k1')},${_emoji('k2')}'),
            _comment('a', '{"text":"plain text only"}'),
          ],
        }),
        interactionsByChannelProvider(QueueItemKind.liveChat).overrideWithValue(
          {
            'a': [_chat('a', '${_emoji('k2')},${_emoji('k2')}')],
            'b': [_chat('b', _emoji('k1'))],
            'c': [_chat('c', '{"text":"no emojis \u{1F525}"}')],
          },
        ),
        emojiNamesByKeyProvider.overrideWithValue(names),
        channelsProvider.overrideWithValue(_channels),
        for (final channel in _channels)
          channelByIdProvider(channel.channelId).overrideWithValue(channel),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('counts each channel custom emoji, most used first', () {
    final emojis = container(names: {'k2': 'wave'}).read(channelEmojisProvider);

    expect(emojis.keys, unorderedEquals(['a', 'b']));
    expect(emojis['a'], [
      const ChannelEmoji(
        key: 'k2',
        url: 'https://yt3.ggpht.com/k2',
        name: 'wave',
        channelId: 'a',
        usageCount: 3,
        resolved: true,
      ),
      ChannelEmoji(
        key: 'k1',
        url: 'https://yt3.ggpht.com/k1',
        name: fallbackEmojiName('k1'),
        channelId: 'a',
        usageCount: 1,
        resolved: false,
      ),
    ]);
    expect(emojis['b']!.single.usageCount, 1);
  });

  test('gives picker sections in channel list order', () {
    final c = container();
    final groups = c.read(allChannelEmojiGroupsProvider);

    expect([for (final g in groups) g.channelId], ['b', 'a']);
    expect(groups.first.channelTitle, 'Bee');
    expect(groups.first.thumbnailUrl, 'bee');
    expect(groups.last.emojis, c.read(channelEmojisProvider)['a']);
  });

  test("gives one channel's picker section", () {
    final c = container();

    expect(c.read(channelEmojiGroupsProvider('a')), [
      ChannelEmojiGroup(
        channelId: 'a',
        channelTitle: 'Ay',
        emojis: c.read(channelEmojisProvider)['a']!,
      ),
    ]);
    expect(c.read(channelEmojiGroupsProvider('c')), isEmpty);
  });

  test('the shared emoji scans cannot be changed by their readers', () {
    final c = container();
    final scans = c.read(channelEmojiScansProvider);
    final scan = scans['a']!;

    expect(() => scans.remove('a'), throwsUnsupportedError);
    expect(() => scan.customCounts['k1'] = 99, throwsUnsupportedError);
    expect(() => scan.customUrls.clear(), throwsUnsupportedError);
    expect(() => scan.standardEmojis.clear(), throwsUnsupportedError);
    expect(() => scan.videoIds.add('v9'), throwsUnsupportedError);
    expect(c.read(channelEmojisProvider)['a'], hasLength(2));
  });
}
