import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/youtube_links.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';

Comment _comment({String? videoId, String? postId}) => Comment(
  commentId: 'c1',
  channelId: 'UCme',
  createdAt: DateTime.utc(2026),
  price: 0,
  videoId: videoId,
  postId: postId,
  rawCommentText: '',
  displayText: '',
);

void main() {
  test('a comment on a video links to itself on that video', () {
    final url = youtubeUrlOf(_comment(videoId: 'v1'))!;

    expect(url.path, '/watch');
    expect(url.queryParameters, {'v': 'v1', 'lc': 'c1'});
  });

  test('a comment on a post links to itself on that post', () {
    final url = youtubeUrlOf(_comment(postId: 'p1'))!;

    expect(url.path, youtubePostUrl('p1').path);
    expect(url.queryParameters, {'lc': 'c1'});
  });

  test('a comment on neither has no link', () {
    expect(youtubeUrlOf(_comment()), isNull);
  });

  test('a live chat links to its video', () {
    final chat = LiveChat(
      liveChatId: 'l1',
      channelId: 'UCme',
      createdAt: DateTime.utc(2026),
      price: 0,
      videoId: 'v1',
      rawText: '',
      displayText: '',
    );

    expect(youtubeUrlOf(chat), youtubeVideoUrl('v1'));
  });
}
