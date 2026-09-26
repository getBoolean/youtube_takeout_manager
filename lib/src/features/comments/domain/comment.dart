import 'package:dart_mappable/dart_mappable.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';

part 'comment.mapper.dart';

@MappableClass()
class Comment with CommentMappable implements Interaction {
  final String commentId;
  final String channelId;
  @override
  final DateTime createdAt;
  final double price;
  final String? parentCommentId;
  final String? postId;
  @override
  final String? videoId;
  final String rawCommentText;
  @override
  final String displayText;
  final String? topLevelCommentId;

  const Comment({
    required this.commentId,
    required this.channelId,
    required this.createdAt,
    required this.price,
    this.parentCommentId,
    this.postId,
    this.videoId,
    required this.rawCommentText,
    required this.displayText,
    this.topLevelCommentId,
  });

  @override
  String get id => commentId;
  @override
  QueueItemKind get kind => QueueItemKind.comment;
  @override
  String get rawText => rawCommentText;
}
