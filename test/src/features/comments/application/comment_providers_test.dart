import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

Comment _comment(String id, int year) => Comment(
  commentId: id,
  channelId: 'UCme',
  createdAt: DateTime(year),
  price: 0,
  rawCommentText: '{"text":"$id"}',
  displayText: id,
);

LiveChat _chat(String id, int year) => LiveChat(
  liveChatId: id,
  channelId: 'UCme',
  createdAt: DateTime(year),
  price: 0,
  rawText: '{"text":"$id"}',
  displayText: id,
);

class _NoVideoMetadata extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value({});
}

void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        allCommentsProvider.overrideWithValue([
          _comment('old', 2020),
          _comment('new', 2024),
        ]),
        allLiveChatsProvider.overrideWithValue([
          _chat('old', 2020),
          _chat('new', 2024),
        ]),
        videoMetadataProvider.overrideWith(_NoVideoMetadata.new),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a channel\'s comments are newest first, without reordering the '
      'comments by channel', () {
    final c = container();

    final sorted = c.read(channelCommentsProvider(unknownChannelId));

    expect([for (final i in sorted) i.commentId], ['new', 'old']);
    expect(
      [
        for (final i in c.read(commentsByChannelProvider)[unknownChannelId]!)
          i.commentId,
      ],
      ['old', 'new'],
    );
  });

  test('a channel\'s live chats are newest first, without reordering the '
      'live chats by channel', () {
    final c = container();

    final sorted = c.read(channelLiveChatsProvider(unknownChannelId));

    expect([for (final i in sorted) i.liveChatId], ['new', 'old']);
    expect(
      [
        for (final i in c.read(liveChatsByChannelProvider)[unknownChannelId]!)
          i.liveChatId,
      ],
      ['old', 'new'],
    );
  });
}
