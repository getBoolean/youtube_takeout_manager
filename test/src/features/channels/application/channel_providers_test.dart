import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

Comment _comment(String id, String videoId) => Comment(
  commentId: id,
  channelId: 'UCme',
  createdAt: DateTime(2024),
  price: 0,
  videoId: videoId,
  rawCommentText: '{"text":"$id"}',
  displayText: id,
);

LiveChat _chat(String id, String videoId) => LiveChat(
  liveChatId: id,
  channelId: 'UCme',
  createdAt: DateTime(2024),
  price: 0,
  videoId: videoId,
  rawText: '{"text":"$id"}',
  displayText: id,
);

class _Videos extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value(const {
    'va': Video(videoId: 'va', channelId: 'UCa', channelTitle: 'A on video'),
    'vb': Video(videoId: 'vb', channelId: 'UCb', channelTitle: 'B on video'),
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('channelsProvider', () {
    Future<List<Channel>> channels() async {
      final c = ProviderContainer(
        overrides: [
          viewedTakeoutProvider.overrideWithValue(
            AsyncData(
              TakeoutData(
                // UCa: one comment and one live chat; UCb: three comments.
                comments: [
                  _comment('a1', 'va'),
                  _comment('b1', 'vb'),
                  _comment('b2', 'vb'),
                  _comment('b3', 'vb'),
                ],
                liveChats: [_chat('a2', 'va')],
                subscriptionsByChannelId: const {
                  'UCa': Subscription(
                    channelId: 'UCa',
                    channelUrl: 'https://www.youtube.com/channel/UCa',
                    channelTitle: 'A subscribed',
                  ),
                },
              ),
            ),
          ),
          videoMetadataProvider.overrideWith(_Videos.new),
        ],
      );
      addTearDown(c.dispose);
      c.listen(videoMetadataProvider, (_, _) {});
      await c.read(videoMetadataProvider.future);
      return c.read(channelsProvider);
    }

    test('lists the channels with the most interactions first', () async {
      final list = await channels();

      expect([for (final ch in list) ch.channelId], ['UCb', 'UCa']);
      expect(list.first.totalInteractions, 3);
      expect(list.last.totalInteractions, 2);
    });

    test('names a channel by its subscription before its videos', () async {
      final byId = {for (final ch in await channels()) ch.channelId: ch};

      expect(byId['UCa']!.channelTitle, 'A subscribed');
      expect(byId['UCb']!.channelTitle, 'B on video');
    });
  });

  group('filteredChannelsProvider', () {
    const titled = Channel(
      channelId: 'UCtitled',
      channelTitle: 'Café Radio',
      commentCount: 1,
      liveChatCount: 0,
    );
    const untitled = Channel(
      channelId: 'UCNoTitleYet',
      commentCount: 1,
      liveChatCount: 0,
    );
    const other = Channel(
      channelId: 'UCother',
      channelTitle: 'Gardening',
      commentCount: 1,
      liveChatCount: 0,
    );

    List<String> search(String query) {
      final c = ProviderContainer(
        overrides: [
          channelsProvider.overrideWithValue(const [titled, untitled, other]),
        ],
      );
      addTearDown(c.dispose);
      c.listen(channelSearchQueryProvider, (_, _) {});
      c.read(channelSearchQueryProvider.notifier).update(query);
      return [for (final ch in c.read(filteredChannelsProvider)) ch.channelId];
    }

    test('shows every channel without a query', () {
      expect(search(''), hasLength(3));
    });

    test('matches the title whatever its case', () {
      expect(search('CAFÉ'), [titled.channelId]);
      expect(search('radio'), [titled.channelId]);
    });

    test('matches a channel without a title by its ID', () {
      expect(search('notitle'), [untitled.channelId]);
    });
  });
}
