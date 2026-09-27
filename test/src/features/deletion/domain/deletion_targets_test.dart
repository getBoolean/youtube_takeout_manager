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

  test('narrowing keeps the IDs asked for, with their kind and text', () {
    const targets = DeletionTargets(
      commentSnippets: {'c1': 'one', 'c2': 'two'},
      liveChatSnippets: {'l1': 'chat', 'l2': null},
    );

    final narrowed = targets.only({'c2', 'l2', 'elsewhere'});

    expect(narrowed.commentSnippets, {'c2': 'two'});
    expect(narrowed.liveChatSnippets, {'l2': null});
  });

  group('possible membership events', () {
    LiveChat chat(String id, String rawText) => LiveChat(
      liveChatId: id,
      channelId: 'UCme',
      createdAt: DateTime(2024),
      price: 0,
      rawText: rawText,
      displayText: rawText,
    );

    test("counts the targets' live chats with no text in the takeout", () {
      const targets = DeletionTargets(
        commentSnippets: {'empty-comment': ''},
        liveChatSnippets: {'blank': null, 'spaces': '', 'said': 'hi'},
      );

      final count = targets.possibleMembershipEventsIn([
        chat('blank', ''),
        chat('spaces', '   '),
        chat('said', 'hi'),
        chat('not-a-target', ''),
      ]);

      expect(count, 2);
    });

    test("goes by the takeout's text, not the queue's snippet", () {
      // Items queued by ID alone have no snippet.
      const byId = DeletionTargets(liveChatSnippets: {'said': null});
      expect(byId.possibleMembershipEventsIn([chat('said', 'hi')]), 0);

      const shortened = DeletionTargets(liveChatSnippets: {'blank': '...'});
      expect(shortened.possibleMembershipEventsIn([chat('blank', ' ')]), 1);
    });

    test("leaves out live chats the takeout doesn't have", () {
      const targets = DeletionTargets(liveChatSnippets: {'gone': null});

      expect(targets.possibleMembershipEventsIn(const []), 0);
    });
  });
}
