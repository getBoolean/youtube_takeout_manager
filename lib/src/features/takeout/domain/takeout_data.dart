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

/// How many comments and live chats a channel wrote.
typedef ItemCounts = ({int comments, int liveChats});

/// Who wrote a takeout's items, and which of its channels is the main one.
extension TakeoutDataAuthors on TakeoutData {
  /// How many comments and live chats each channel wrote, by author channel
  /// ID, '' for rows without one.
  Map<String, ItemCounts> get countsByAuthor {
    final counts = <String, ItemCounts>{};
    for (final c in comments) {
      final n = counts[c.channelId] ?? (comments: 0, liveChats: 0);
      counts[c.channelId] = (comments: n.comments + 1, liveChats: n.liveChats);
    }
    for (final l in liveChats) {
      final n = counts[l.channelId] ?? (comments: 0, liveChats: 0);
      counts[l.channelId] = (comments: n.comments, liveChats: n.liveChats + 1);
    }
    return counts;
  }

  /// The channels that wrote its items. Rows without a Channel ID are left
  /// out.
  Set<String> get authorChannelIds => countsByAuthor.keys.toSet()..remove('');

  /// When its newest comment or live chat was written, or null if it has
  /// none.
  DateTime? get newestItemAt {
    DateTime? newest;
    for (final t in [
      for (final c in comments) c.createdAt,
      for (final l in liveChats) l.createdAt,
    ]) {
      if (newest == null || t.isAfter(newest)) newest = t;
    }
    return newest;
  }

  /// The channel that wrote most of its comments and live chats, or null if
  /// it has none.
  String? get mostCommonAuthor => mostCommonAuthorIn([this]);

  /// The main channel its channel.csv names, see [listedMainChannelId].
  String? get listedMainChannelId => listedMainChannelIdOf(ownChannels);

  /// Its main channel when saved under [takeoutId]: the one its channel.csv
  /// names, otherwise the one it's saved under.
  String mainChannelId(String takeoutId) => listedMainChannelId ?? takeoutId;

  /// The channel that wrote a row with [channelId] when saved under
  /// [takeoutId]. Rows without a Channel ID are the main channel's.
  String authorOf(String channelId, {required String takeoutId}) =>
      authorChannelId(channelId, mainChannelId: mainChannelId(takeoutId));
}

/// The channel that wrote a row with [channelId]: rows without a Channel ID
/// are [mainChannelId]'s.
String authorChannelId(String channelId, {required String mainChannelId}) =>
    channelId.isEmpty ? mainChannelId : channelId;

/// The channel that wrote most items across [data], or null if none did.
String? mostCommonAuthorIn(Iterable<TakeoutData> data) {
  final counts = <String, int>{};
  for (final d in data) {
    for (final MapEntry(key: id, value: n) in d.countsByAuthor.entries) {
      if (id.isNotEmpty) {
        counts[id] = (counts[id] ?? 0) + n.comments + n.liveChats;
      }
    }
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

/// The main channel of a takeout whose channel.csv lists [own]: the only
/// one listed, or null when it lists none or several.
String? listedMainChannelIdOf(Map<String, OwnChannel> own) =>
    own.length == 1 ? own.keys.single : null;
