import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../domain/takeout_data.dart';
import 'takeout_files.dart';
import 'takeout_meta_codec.dart';

final _csv = Csv();

/// Encodes [data] as takeout-style CSV files that [parseCsvFiles] reads back
/// into the same data, so merged takeouts can be saved like a fresh export.
Map<String, Uint8List> encodeTakeoutCsvs(TakeoutData data) => {
  TakeoutFile.channels.path: _encode([
    ['Channel ID', 'Channel Title (Original)'],
    for (final c in data.ownChannels.values) [c.channelId, c.title ?? ''],
  ]),
  TakeoutFile.channelUrlConfigs.path: _encode([
    ['Channel ID', 'Channel Vanity URL 1 Name'],
    for (final c in data.ownChannels.values)
      if (c.vanityName case final name?) [c.channelId, name],
  ]),
  TakeoutFile.channelCounts.path: encodeChannelCounts(data.countsByAuthor),
  TakeoutFile.comments.path: _encode([
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
  TakeoutFile.liveChats.path: _encode([
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
  TakeoutFile.subscriptions.path: _encode([
    ['Channel Id', 'Channel Url', 'Channel Title'],
    for (final s in data.subscriptionsByChannelId.values)
      [s.channelId, s.channelUrl, s.channelTitle],
  ]),
  TakeoutFile.meta.path: encodeTakeoutMeta(data),
};

String _timestamp(DateTime t) => t.toUtc().toIso8601String();

Uint8List _encode(List<List<Object>> rows) =>
    Uint8List.fromList(utf8.encode(_csv.encode(rows)));
