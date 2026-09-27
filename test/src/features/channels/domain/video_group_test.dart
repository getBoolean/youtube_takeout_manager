import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/domain/video_group.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

Comment _comment(String id, int day, {String? videoId, String? postId}) =>
    Comment(
      commentId: id,
      channelId: 'UCme',
      createdAt: DateTime(2024, 1, day),
      price: 0,
      videoId: videoId,
      postId: postId,
      rawCommentText: '{"text":"$id"}',
      displayText: id,
    );

LiveChat _chat(String id, int day, {String? videoId}) => LiveChat(
  liveChatId: id,
  channelId: 'UCme',
  createdAt: DateTime(2024, 1, day),
  price: 0,
  videoId: videoId,
  rawText: '{"text":"$id"}',
  displayText: id,
);

/// Each group as "video or post ID (type): item IDs".
List<String> _summary(List<VideoGroup<Interaction>> groups) => [
  for (final g in groups)
    '${g.videoId ?? g.postId ?? '-'} (${g.groupType.name}): '
        '${g.items.map((i) => i.id).join(', ')}',
];

void main() {
  test('comments group by video, newest first, then posts, then the rest', () {
    // Newest first, as a channel's comments come.
    final groups = groupByVideo([
      _comment('orphan', 9),
      _comment('post', 8, postId: 'p1'),
      _comment('b2', 7, videoId: 'b'),
      _comment('a2', 6, videoId: 'a'),
      _comment('b1', 5, videoId: 'b'),
      _comment('a1', 4, videoId: 'a'),
    ]);

    expect(_summary(groups), [
      'b (video): b2, b1',
      'a (video): a2, a1',
      'p1 (post): post',
      '- (orphaned): orphan',
    ]);
  });

  test('live chats group by video, newest first, then the rest', () {
    final groups = groupByVideo([
      _chat('orphan', 9),
      _chat('a2', 7, videoId: 'a'),
      _chat('b1', 6, videoId: 'b'),
      _chat('a1', 5, videoId: 'a'),
    ]);

    expect(_summary(groups), [
      'a (video): a2, a1',
      'b (video): b1',
      '- (orphaned): orphan',
    ]);
  });

  test('a video and a post with the same ID are different groups', () {
    final groups = groupByVideo([
      _comment('on-video', 2, videoId: 'x'),
      _comment('on-post', 1, postId: 'x'),
    ]);

    expect(groups.map((g) => g.groupKey).toSet(), hasLength(2));
  });

  test('a group is titled by its video, its post, or as other', () {
    const video = Video(videoId: 'v1', channelId: 'UCch', title: 'A video');

    expect(const VideoGroup<Comment>.video('v1', []).title(video), 'A video');
    expect(const VideoGroup<Comment>.video('v1', []).title(null), 'Video: v1');
    expect(
      const VideoGroup<Comment>.post('p1', []).title(null),
      'Community Post: p1',
    );
    expect(const VideoGroup<Comment>.other([]).title(null), 'Other');
  });
}
