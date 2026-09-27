import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'queue_item_kind.dart';

/// Stands in for the channel of comments and live chats whose video's
/// channel isn't known: its details aren't loaded (e.g. signed out), the
/// video is gone, or the item is on a post. Never a real channel ID, which
/// always starts with "UC".
const unknownChannelId = '_unknown';

/// A comment or live chat from the takeout, as the lists, search and
/// deletion see it.
///
/// Only [Comment] and [LiveChat] implement it. Dart can't seal it, since
/// they're in their own libraries, so [when] stands in for an exhaustive
/// `switch`.
abstract interface class Interaction {
  String get id;
  QueueItemKind get kind;
  DateTime get createdAt;

  /// The video it was posted on, if any.
  String? get videoId;

  /// The community post it was posted on, if any. Live chats are only ever
  /// on videos.
  String? get postId;

  /// The text as exported, emoji included; see `parseCommentSegments`.
  String get rawText;

  /// The text as plain text.
  String get displayText;

  /// Calls [comment] or [liveChat], whichever this is.
  T when<T>({
    required T Function(Comment) comment,
    required T Function(LiveChat) liveChat,
  });
}

/// [items] split into their comments and live chats, each kept in order.
({List<Comment> comments, List<LiveChat> liveChats}) splitInteractions(
  Iterable<Interaction> items,
) {
  final comments = <Comment>[];
  final liveChats = <LiveChat>[];
  for (final item in items) {
    item.when(comment: comments.add, liveChat: liveChats.add);
  }
  return (comments: comments, liveChats: liveChats);
}
