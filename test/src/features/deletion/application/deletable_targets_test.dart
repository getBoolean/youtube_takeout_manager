import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletable_targets.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';

Comment _comment(String id) => Comment(
  commentId: id,
  channelId: 'UC1',
  createdAt: DateTime.utc(2026),
  price: 0,
  rawCommentText: '',
  displayText: 'comment $id',
);

LiveChat _liveChat(String id) => LiveChat(
  liveChatId: id,
  channelId: 'UC1',
  createdAt: DateTime.utc(2026),
  price: 0,
  rawText: '',
  displayText: 'chat $id',
);

void main() {
  test('leaves out skipped comments and live chats', () {
    final targets = deletableTargets(
      comments: [_comment('c1'), _comment('c2')],
      liveChats: [_liveChat('l1'), _liveChat('l2')],
      skipCommentIds: {'c2'},
      skipLiveChatIds: {'l1'},
    );

    expect(targets.commentSnippets, {'c1': 'comment c1'});
    expect(targets.liveChatSnippets, {'l2': 'chat l2'});
  });

  test('is empty when everything is skipped', () {
    final targets = deletableTargets(
      comments: [_comment('c1')],
      skipCommentIds: {'c1'},
    );

    expect(targets.isEmpty, isTrue);
  });
}
