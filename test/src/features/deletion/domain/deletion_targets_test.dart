import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';

void main() {
  test('items become targets of their own kind, with their text', () {
    final targets = DeletionTargets.of([
      Comment(
        commentId: 'c',
        channelId: 'UCme',
        createdAt: DateTime(2024),
        price: 0,
        rawCommentText: '{"text":"a comment"}',
        displayText: 'a comment',
      ),
      LiveChat(
        liveChatId: 'l',
        channelId: 'UCme',
        createdAt: DateTime(2024),
        price: 0,
        rawText: '{"text":"a chat"}',
        displayText: 'a chat',
      ),
    ]);

    expect(targets.commentSnippets, {'c': 'a comment'});
    expect(targets.liveChatSnippets, {'l': 'a chat'});
    expect(targets.idsOf(QueueItemKind.comment), {'c'});
    expect(targets.idsOf(QueueItemKind.liveChat), {'l'});
  });

  test('bare IDs become targets of the kind they are listed under', () {
    final targets = DeletionTargets.ids({
      QueueItemKind.comment: {'c1', 'c2'},
      QueueItemKind.liveChat: {'l'},
    });

    expect(targets.commentSnippets, {'c1': null, 'c2': null});
    expect(targets.liveChatSnippets, {'l': null});
  });
}
