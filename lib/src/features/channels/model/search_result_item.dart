import 'package:youtube_takeout_manager/src/features/comments/model/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/model/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/model/live_chat.dart';

/// A unified wrapper around [Comment] or [LiveChat] so cross-channel search
/// results can render in a single heterogeneous list.
///
/// [channelId] is passed explicitly rather than read from the underlying
/// record because the rest of the app addresses channels by the video's
/// channelId (from YouTube metadata), which may differ from the value stored
/// on the CSV row.
sealed class SearchResultItem {
  const SearchResultItem();

  String get id;
  String get channelId;
  DateTime get createdAt;
  String get displayText;
  String get rawText;
  QueueItemKind get kind;
}

final class CommentResult extends SearchResultItem {
  final Comment comment;
  @override
  final String channelId;

  const CommentResult(this.comment, {required this.channelId});

  @override
  String get id => comment.commentId;
  @override
  DateTime get createdAt => comment.createdAt;
  @override
  String get displayText => comment.displayText;
  @override
  String get rawText => comment.rawCommentText;
  @override
  QueueItemKind get kind => QueueItemKind.comment;
}

final class LiveChatResult extends SearchResultItem {
  final LiveChat liveChat;
  @override
  final String channelId;

  const LiveChatResult(this.liveChat, {required this.channelId});

  @override
  String get id => liveChat.liveChatId;
  @override
  DateTime get createdAt => liveChat.createdAt;
  @override
  String get displayText => liveChat.displayText;
  @override
  String get rawText => liveChat.rawText;
  @override
  QueueItemKind get kind => QueueItemKind.liveChat;
}
