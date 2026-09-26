import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/cross_channel_search_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

const _me = 'UCme';

Comment _comment(String id, {String? videoId, String? postId}) => Comment(
  commentId: id,
  channelId: _me,
  createdAt: DateTime(2024),
  price: 0,
  videoId: videoId,
  postId: postId,
  rawCommentText: '{"text":"$id"}',
  displayText: id,
);

LiveChat _chat(String id, {String? videoId}) => LiveChat(
  liveChatId: id,
  channelId: _me,
  createdAt: DateTime(2024),
  price: 0,
  videoId: videoId,
  rawText: '{"text":"$id"}',
  displayText: id,
);

final _comments = [
  _comment('known', videoId: 'v1'),
  // Details not loaded, or the video is gone.
  _comment('needle-missing-video', videoId: 'v2'),
  _comment('on-post', postId: 'p1'),
  _comment('orphan'),
];

final _liveChats = [
  _chat('chat-known', videoId: 'v1'),
  _chat('chat-missing', videoId: 'v3'),
];

class _FakeVideoMetadata extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value({
    'v1': const Video(
      videoId: 'v1',
      channelId: 'UCknown',
      channelTitle: 'Known',
    ),
  });
}

class _FakeTakeout extends TakeoutNotifier {
  @override
  Future<LoadedTakeout?> build() async => LoadedTakeout(
    id: _me,
    data: TakeoutData(
      comments: _comments,
      liveChats: _liveChats,
      subscriptionsByChannelId: const {},
    ),
  );
}

/// Keeps the fake takeout's ID selected.
class _Selection extends TakeoutSelectionNotifier {
  @override
  Future<TakeoutSelection?> build() async =>
      const TakeoutSelection(takeoutId: _me);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> container() async {
    final c = ProviderContainer(
      overrides: [
        takeoutProvider.overrideWith(_FakeTakeout.new),
        takeoutSelectionProvider.overrideWith(_Selection.new),
        allCommentsProvider.overrideWithValue(_comments),
        allLiveChatsProvider.overrideWithValue(_liveChats),
        videoMetadataProvider.overrideWith(_FakeVideoMetadata.new),
      ],
    );
    addTearDown(c.dispose);
    c
      ..listen(takeoutProvider, (_, _) {})
      ..listen(takeoutSelectionProvider, (_, _) {})
      ..listen(videoMetadataProvider, (_, _) {});
    await c.read(takeoutProvider.future);
    await c.read(takeoutSelectionProvider.future);
    await c.read(videoMetadataProvider.future);
    return c;
  }

  test(
    'items with no known video channel are grouped as unknown, not dropped',
    () async {
      final c = await container();

      final comments = c.read(commentsByChannelProvider);
      expect(comments.keys, unorderedEquals(['UCknown', unknownChannelId]));
      expect(
        comments[unknownChannelId]!.map((c) => c.commentId),
        unorderedEquals(['needle-missing-video', 'on-post', 'orphan']),
      );

      final liveChats = c.read(liveChatsByChannelProvider);
      expect(liveChats[unknownChannelId]!.map((c) => c.liveChatId), [
        'chat-missing',
      ]);
    },
  );

  test('the unknown group is listed last, even with the most items', () async {
    final c = await container();

    final channels = c.read(channelsProvider);
    expect(channels.map((ch) => ch.channelId), ['UCknown', unknownChannelId]);
    final unknown = channels.last;
    expect(unknown.isUnknown, isTrue);
    expect(unknown.channelTitle, 'Unknown channel');
    expect(unknown.channelUrl, isNull);
    expect(unknown.commentCount, 3);
    expect(unknown.liveChatCount, 1);

    expect(c.read(channelByIdProvider(unknownChannelId))?.isUnknown, isTrue);
  });

  test('cross-channel search finds items whose video is unknown', () async {
    final c = await container();
    c.listen(crossChannelSearchItemsProvider, (_, _) {});
    c.read(channelSearchQueryProvider.notifier).update('needle');

    final results = c.read(crossChannelSearchItemsProvider);
    expect(results.map((r) => r.id), ['needle-missing-video']);
    expect(results.single.channelId, unknownChannelId);
  });
}
