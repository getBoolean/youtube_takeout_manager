import 'package:dart_mappable/dart_mappable.dart';

part 'comment.mapper.dart';

@MappableClass()
class Comment with CommentMappable {
  final String commentId;
  final String channelId;
  final DateTime createdAt;
  final double price;
  final String? parentCommentId;
  final String? postId;
  final String? videoId;
  final String rawCommentText;
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
}
