import 'package:dart_mappable/dart_mappable.dart';

part 'quota_operation.mapper.dart';

/// YouTube Data API v3 operations and their quota costs.
///
/// Costs from https://developers.google.com/youtube/v3/determine_quota_cost
@MappableEnum()
enum QuotaOperation {
  deleteComment(deleteCost),
  deleteLiveChat(deleteCost),
  videosList(1),
  channelsList(1);

  const QuotaOperation(this.cost);
  final int cost;

  /// What any delete costs: comments and live chats both go through
  /// `comments.delete`.
  static const deleteCost = 50;
}
