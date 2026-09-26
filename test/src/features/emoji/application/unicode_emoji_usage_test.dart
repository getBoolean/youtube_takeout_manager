import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/search_options_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/unicode_emoji.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

const _fire = '\u{1F525}';
const _grinning = '\u{1F600}';
const _thumbsUpMedium = '\u{1F44D}\u{1F3FD}';
const _redCircle = '\u{1F534}';

Comment _comment(String channelId, String raw) => Comment(
  commentId: raw,
  channelId: channelId,
  createdAt: DateTime(2024),
  price: 0,
  rawCommentText: raw,
  displayText: raw,
);

LiveChat _chat(String channelId, String raw, {String? videoId}) => LiveChat(
  liveChatId: raw,
  channelId: channelId,
  createdAt: DateTime(2024),
  price: 0,
  videoId: videoId,
  rawText: raw,
  displayText: raw,
);

class _FakeVideoMetadata extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value({
    'v1': const Video(
      videoId: 'v1',
      channelId: 'a',
      title: '$_redCircle LIVE $_fire',
    ),
    // Not a video the user commented or chatted on.
    'v2': const Video(videoId: 'v2', channelId: 'a', title: _grinning),
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [
        interactionsByChannelProvider(QueueItemKind.comment).overrideWithValue({
          'a': [
            _comment('a', '{"text":"so lit $_fire$_fire"}'),
            _comment('a', '{"text":"plain text only"}'),
          ],
        }),
        interactionsByChannelProvider(
          QueueItemKind.liveChat,
        ).overrideWithValue({
          'a': [_chat('a', '{"text":"nice $_thumbsUpMedium"}', videoId: 'v1')],
          'b': [
            _chat('b', '{"text":"hi $_grinning"}'),
            // A channel emoji isn't a standard one.
            _chat(
              'b',
              '{"text":"","emoji":{"customEmojiUrl":"https://yt3.ggpht.com/k"}}',
            ),
          ],
        }),
        videoMetadataProvider.overrideWith(_FakeVideoMetadata.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Loads video titles and search options. Providers nobody listens to are
  /// paused, so listen before waiting.
  Future<void> settle(ProviderContainer c) async {
    c
      ..listen(videoMetadataProvider, (_, _) {})
      ..listen(searchOptionsProvider, (_, _) {});
    await c.read(videoMetadataProvider.future);
    await c.read(searchOptionsProvider.future);
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

  test(
    'adds emojis in the titles of videos the channel search covers',
    () async {
      final c = container();
      await settle(c);
      expect(names(c.read(channelUnicodeEmojisProvider('a'))), [
        'thumbsup',
        'fire',
        'red_circle',
      ]);
    },
  );

  test('leaves title emojis out while titles are not searched', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.search.matchGroupTitles': false,
    });
    final c = container();
    await settle(c);
    expect(names(c.read(channelUnicodeEmojisProvider('a'))), [
      'thumbsup',
      'fire',
    ]);
  });

  test('lists the standard emojis used anywhere', () {
    expect(names(container().read(allUsedUnicodeEmojisProvider)), [
      'grinning',
      'thumbsup',
      'fire',
    ]);
  });
}
