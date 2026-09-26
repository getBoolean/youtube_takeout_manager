import 'queue_item_kind.dart';

/// Stands in for the channel of comments and live chats whose video's
/// channel isn't known: its details aren't loaded (e.g. signed out), the
/// video is gone, or the item is on a post. Never a real channel ID, which
/// always starts with "UC".
const unknownChannelId = '_unknown';

/// A comment or live chat from the takeout, as the lists, search and
/// deletion see it.
abstract interface class Interaction {
  String get id;
  QueueItemKind get kind;
  DateTime get createdAt;

  /// The video it was posted on, if any.
  String? get videoId;

  /// The text as exported, emoji included; see `parseCommentSegments`.
  String get rawText;

  /// The text as plain text.
  String get displayText;
}
