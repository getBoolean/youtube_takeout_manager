import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';

Comment _comment(String id) => Comment(
  commentId: id,
  channelId: 'UC1',
  createdAt: DateTime(2024),
  price: 0,
  videoId: 'v1',
  rawCommentText: '{"text":"hi"}',
  displayText: 'hi',
);

LiveChat _chat(String id) => LiveChat(
  liveChatId: id,
  channelId: 'UC1',
  createdAt: DateTime(2024),
  price: 0,
  videoId: 'v1',
  rawText: 'hi',
  displayText: 'hi',
);

void main() {
  group('Interaction.when', () {
    String describe(Interaction item) => item.when(
      comment: (c) => 'comment ${c.commentId}',
      liveChat: (l) => 'live chat ${l.liveChatId}',
    );

    test('hands a comment to the comment callback', () {
      expect(describe(_comment('c1')), 'comment c1');
    });

    test('hands a live chat to the live chat callback', () {
      expect(describe(_chat('l1')), 'live chat l1');
    });
  });

  test('splitInteractions sorts a mix into comments and live chats', () {
    final c1 = _comment('c1');
    final c2 = _comment('c2');
    final l1 = _chat('l1');

    final (:comments, :liveChats) = splitInteractions([c1, l1, c2]);

    expect(comments, [c1, c2]);
    expect(liveChats, [l1]);
  });
}
