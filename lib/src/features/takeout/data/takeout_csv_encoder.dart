import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../domain/takeout_data.dart';

const _youtubeDir = 'Takeout/YouTube and YouTube Music';

/// Where [encodeTakeoutCsvs] stores what the takeout CSVs can't hold: the
/// export time and the skipped row counts.
const takeoutMetaPath = '_meta/takeout_meta.csv';

/// Where [encodeTakeoutCsvs] stores how many comments and live chats each
/// channel wrote, so the takeout switcher needn't load them all.
const takeoutChannelsMetaPath = '_meta/takeout_channels.csv';

/// How a takeout's channel list and vanity names end, lowercased.
const channelsCsvPath = 'channels/channel.csv';
const channelUrlConfigsCsvPath = 'channels/channel url configs.csv';

/// Whether [path] is one of the small saved files a takeout's summary is
/// read from, rather than its comments, live chats or subscriptions.
bool isTakeoutSummaryPath(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith(takeoutMetaPath) ||
      lower.endsWith(takeoutChannelsMetaPath) ||
      lower.endsWith(channelsCsvPath) ||
      lower.endsWith(channelUrlConfigsCsvPath);
}

final _csv = Csv();

/// Encodes [data] as takeout-style CSV files that [parseCsvFiles] reads back
/// into the same data, so merged takeouts can be saved like a fresh export.
Map<String, Uint8List> encodeTakeoutCsvs(TakeoutData data) {
  // By author channel ID, '' for rows without one.
  final counts = <String, ({int comments, int liveChats})>{};
  for (final c in data.comments) {
    final n = counts[c.channelId] ?? (comments: 0, liveChats: 0);
    counts[c.channelId] = (comments: n.comments + 1, liveChats: n.liveChats);
  }
  for (final l in data.liveChats) {
    final n = counts[l.channelId] ?? (comments: 0, liveChats: 0);
    counts[l.channelId] = (comments: n.comments, liveChats: n.liveChats + 1);
  }

  return {
    '$_youtubeDir/channels/channel.csv': _encode([
      ['Channel ID', 'Channel Title (Original)'],
      for (final c in data.ownChannels.values) [c.channelId, c.title ?? ''],
    ]),
    '$_youtubeDir/channels/channel URL configs.csv': _encode([
      ['Channel ID', 'Channel Vanity URL 1 Name'],
      for (final c in data.ownChannels.values)
        if (c.vanityName case final name?) [c.channelId, name],
    ]),
    takeoutChannelsMetaPath: _encode([
      ['Channel ID', 'Comments', 'Live Chats'],
      for (final MapEntry(key: id, value: n) in counts.entries)
        [id, n.comments, n.liveChats],
    ]),
    '$_youtubeDir/comments/comments.csv': _encode([
      [
        'Comment ID',
        'Channel ID',
        'Comment Create Timestamp',
        'Price',
        'Parent Comment ID',
        'Post ID',
        'Video ID',
        'Comment Text',
        'Top-Level Comment ID',
      ],
      for (final c in data.comments)
        [
          c.commentId,
          c.channelId,
          _timestamp(c.createdAt),
          c.price,
          c.parentCommentId ?? '',
          c.postId ?? '',
          c.videoId ?? '',
          c.rawCommentText,
          c.topLevelCommentId ?? '',
        ],
    ]),
    '$_youtubeDir/live chats/live chats.csv': _encode([
      [
        'Live Chat ID',
        'Channel ID',
        'Live Chat Create Timestamp',
        'Price',
        'Currency code',
        'Video ID',
        'Live Chat Text',
      ],
      for (final c in data.liveChats)
        [
          c.liveChatId,
          c.channelId,
          _timestamp(c.createdAt),
          c.price,
          c.currencyCode ?? '',
          c.videoId ?? '',
          c.rawText,
        ],
    ]),
    // Read by position, so the column order matters.
    '$_youtubeDir/subscriptions/subscriptions.csv': _encode([
      ['Channel Id', 'Channel Url', 'Channel Title'],
      for (final s in data.subscriptionsByChannelId.values)
        [s.channelId, s.channelUrl, s.channelTitle],
    ]),
    takeoutMetaPath: _encode([
      [
        'Latest Export At',
        'Skipped Comment Rows',
        'Skipped Live Chat Rows',
        'Comments Exported At',
        'Comments Complete',
        'Live Chats Exported At',
        'Live Chats Complete',
      ],
      [
        _optionalTimestamp(data.latestExportAt),
        data.skippedCommentRows,
        data.skippedLiveChatRows,
        _optionalTimestamp(data.commentsSnapshot?.exportedAt),
        data.commentsSnapshot?.complete ?? '',
        _optionalTimestamp(data.liveChatsSnapshot?.exportedAt),
        data.liveChatsSnapshot?.complete ?? '',
      ],
    ]),
  };
}

String _optionalTimestamp(DateTime? t) => t != null ? _timestamp(t) : '';

String _timestamp(DateTime t) => t.toUtc().toIso8601String();

Uint8List _encode(List<List<Object>> rows) =>
    Uint8List.fromList(utf8.encode(_csv.encode(rows)));
