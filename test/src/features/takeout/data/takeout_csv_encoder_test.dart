import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_csv_encoder.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_parser.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// Quotes a CSV field the way Google Takeout does.
String _q(String s) => '"${s.replaceAll('"', '""')}"';

const _commentsPath = 'Takeout/YouTube and YouTube Music/comments/comments.csv';
const _liveChatsPath =
    'Takeout/YouTube and YouTube Music/live chats/live chats.csv';
const _subscriptionsPath =
    'Takeout/YouTube and YouTube Music/subscriptions/subscriptions.csv';

final _rawComments = [
  'Comment ID,Channel ID,Comment Create Timestamp,Price,Parent Comment ID,'
      'Post ID,Video ID,Comment Text,Top-Level Comment ID',
  'UgzA.AVI3,UCme,2026-04-11T18:26:40.15544+00:00,0,UgzA.AVI2,,SvJU,'
      '${_q('{"text":"@jc","mention":{"channelId":"UCx"}},'
      '{"text":" saves, states\r\nnext line"}')},UgzA',
  'UgxB,UCme,2026-04-12T00:28:56.616747+00:00,0,,post1,,'
      '${_q('{"text":"ends with a quote \\""}')},',
  '0123,UCme,2015-01-01T00:00:00+00:00,0,,,vid9,123,',
].join('\r\n');

final _rawLiveChats = [
  'Live Chat ID,Channel ID,Live Chat Create Timestamp,Price,Currency code,'
      'Video ID,Live Chat Text',
  'Chat1,UCme,2026-03-01T10:00:00.5+00:00,990000,USD,live1,'
      '${_q('{"text":"thanks, \\"streamer\\""}')}',
  'Chat2,UCme,2026-03-01T10:05:00+00:00,0,,live1,${_q('{"text":"hi"}')}',
].join('\r\n');

final _rawSubscriptions = [
  'Channel Id,Channel Url,Channel Title',
  'UCsub,http://www.youtube.com/channel/UCsub,"Sub, With Comma"',
].join('\r\n');

void main() {
  final original = parseCsvFiles({
    _commentsPath: _bytes(_rawComments),
    _liveChatsPath: _bytes(_rawLiveChats),
    _subscriptionsPath: _bytes(_rawSubscriptions),
  });

  test('fixture parses as expected', () {
    expect(original.comments.map((c) => c.commentId), [
      'UgzA.AVI3',
      'UgxB',
      '0123',
    ]);
    expect(original.comments.last.rawCommentText, '123');
    expect(
      original.comments.first.createdAt,
      DateTime.utc(2026, 4, 11, 18, 26, 40, 155, 440),
    );
    expect(original.liveChats.first.price, 990000);
    expect(
      original.subscriptionsByChannelId['UCsub']!.channelTitle,
      'Sub, With Comma',
    );
  });

  test('comments, live chats and subscriptions survive a save and reload', () {
    final reloaded = parseCsvFiles(encodeTakeoutCsvs(original));

    expect(reloaded.comments, original.comments);
    expect(reloaded.liveChats, original.liveChats);
    expect(
      reloaded.subscriptionsByChannelId,
      original.subscriptionsByChannelId,
    );
  });

  test('export times, completeness and skipped row counts survive a save '
      'and reload', () {
    final data = original.copyWith(
      latestExportAt: DateTime.utc(2026, 4, 12, 7, 40, 21),
      skippedCommentRows: 3,
      skippedLiveChatRows: 1,
      commentsSnapshot: KindSnapshot(
        exportedAt: DateTime.utc(2026, 4, 12, 7, 40, 21),
        complete: true,
      ),
      liveChatsSnapshot: KindSnapshot(
        exportedAt: DateTime.utc(2026, 3, 1),
        complete: false,
      ),
    );

    final reloaded = parseCsvFiles(encodeTakeoutCsvs(data));

    expect(reloaded.latestExportAt, DateTime.utc(2026, 4, 12, 7, 40, 21));
    expect(reloaded.skippedCommentRows, 3);
    expect(reloaded.skippedLiveChatRows, 1);
    expect(reloaded.commentsSnapshot, data.commentsSnapshot);
    expect(reloaded.liveChatsSnapshot, data.liveChatsSnapshot);
  });

  test('data saved without an export time reloads without one', () {
    final reloaded = parseCsvFiles(encodeTakeoutCsvs(original));

    expect(reloaded.latestExportAt, isNull);
    expect(reloaded.commentsSnapshot, isNull);
    expect(reloaded.liveChatsSnapshot, isNull);
  });
}
