import 'package:dart_mappable/dart_mappable.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'own_channel.dart';
import 'subscription.dart';

part 'takeout_data.mapper.dart';

@MappableClass()
class TakeoutData with TakeoutDataMappable {
  final List<Comment> comments;
  final List<LiveChat> liveChats;
  final Map<String, Subscription> subscriptionsByChannelId;

  /// Rows skipped due to insufficient columns.
  final int skippedCommentRows;
  final int skippedLiveChatRows;

  /// When the newest takeout merged into this data was exported, or null if
  /// unknown (data saved before export times were tracked).
  final DateTime? latestExportAt;

  /// The newest takeout each kind came from, or null if unknown (data saved
  /// before this was tracked, or none of that kind).
  final KindSnapshot? commentsSnapshot;
  final KindSnapshot? liveChatsSnapshot;

  /// The channels listed in the takeout's `channels/channel.csv`, by ID.
  /// Empty for data saved before they were read.
  final Map<String, OwnChannel> ownChannels;

  const TakeoutData({
    required this.comments,
    required this.liveChats,
    required this.subscriptionsByChannelId,
    this.skippedCommentRows = 0,
    this.skippedLiveChatRows = 0,
    this.latestExportAt,
    this.commentsSnapshot,
    this.liveChatsSnapshot,
    this.ownChannels = const {},
  });
}

/// When the newest takeout holding one kind of item was exported, and
/// whether all of its files of that kind were read. Only a complete snapshot
/// shows that items missing from it are gone from YouTube.
@MappableClass()
class KindSnapshot with KindSnapshotMappable {
  final DateTime exportedAt;
  final bool complete;

  const KindSnapshot({required this.exportedAt, required this.complete});
}
