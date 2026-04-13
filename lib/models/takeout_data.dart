import 'package:dart_mappable/dart_mappable.dart';

import 'comment.dart';
import 'live_chat.dart';
import 'subscription.dart';

part 'takeout_data.mapper.dart';

@MappableClass()
class TakeoutData with TakeoutDataMappable {
  final List<Comment> comments;
  final List<LiveChat> liveChats;
  final Map<String, Subscription> subscriptionsByChannelId;

  /// Raw line counts from CSV files (for diagnostics).
  final int rawCommentLines;
  final int rawLiveChatLines;

  /// Rows the CSV parser produced (excluding header).
  final int parsedCommentRows;
  final int parsedLiveChatRows;

  /// Rows skipped due to insufficient columns.
  final int skippedCommentRows;
  final int skippedLiveChatRows;

  const TakeoutData({
    required this.comments,
    required this.liveChats,
    required this.subscriptionsByChannelId,
    this.rawCommentLines = 0,
    this.rawLiveChatLines = 0,
    this.parsedCommentRows = 0,
    this.parsedLiveChatRows = 0,
    this.skippedCommentRows = 0,
    this.skippedLiveChatRows = 0,
  });
}
