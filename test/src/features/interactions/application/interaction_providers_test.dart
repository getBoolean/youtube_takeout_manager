import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
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
        allInteractionsProvider(
          QueueItemKind.comment,
        ).overrideWithValue([_comment('old', 2020), _comment('new', 2024)]),
        allInteractionsProvider(
          QueueItemKind.liveChat,
        ).overrideWithValue([_chat('old', 2020), _chat('new', 2024)]),
        videoMetadataProvider.overrideWith(_NoVideoMetadata.new),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  for (final kind in QueueItemKind.values) {
    test("a channel's ${kind.name}s are newest first", () {
      final c = container();

      final sorted = c.read(
        channelInteractionsProvider(kind, unknownChannelId),
      );

      expect([for (final i in sorted) i.id], ['new', 'old']);
      expect([for (final i in sorted) i.kind], everyElement(kind));
    });
  }
}
