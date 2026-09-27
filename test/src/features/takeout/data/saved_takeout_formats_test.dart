import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_parser.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_summary_parser.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';

/// Takeouts saved by older versions of the app, as literal files: they must
/// keep loading after the saved format grows.
Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

const _comments = 'Takeout/YouTube and YouTube Music/comments/comments.csv';

final _commentsCsv = _bytes(
  [
    'Comment ID,Channel ID,Comment Create Timestamp,Price,Parent Comment ID,'
        'Post ID,Video ID,Comment Text,Top-Level Comment ID',
    'A,UCme,2026-01-01T00:00:00.000Z,0,,,vid1,"{""text"":""a""}",',
    'B,UCme,2026-01-02T00:00:00.000Z,0,,,vid1,"{""text"":""b""}",',
  ].join('\r\n'),
);

/// Only the takeout's own CSVs, as saved before the app kept its own files.
final _withoutAppFiles = {_comments: _commentsCsv};

/// With the export times file, but from before the per-channel counts and
/// channel list were saved.
final _withoutChannelCounts = {
  _comments: _commentsCsv,
  '_meta/takeout_meta.csv': _bytes(
    'Latest Export At,Skipped Comment Rows,Skipped Live Chat Rows,'
    'Comments Exported At,Comments Complete,Live Chats Exported At,'
    'Live Chats Complete\r\n'
    '2026-02-01T00:00:00.000Z,2,0,2026-02-01T00:00:00.000Z,true,,\r\n',
  ),
};

Map<String, Uint8List> _summaryFiles(Map<String, Uint8List> files) => {
  for (final MapEntry(:key, :value) in files.entries)
    if (isTakeoutSummaryPath(key)) key: value,
};

void main() {
  group('saved before the app kept its own files', () {
    test('its items load, with no export times', () {
      final data = parseCsvFiles(_withoutAppFiles);

      expect(
        data.comments.map((c) => c.commentId),
        unorderedEquals(['A', 'B']),
      );
      expect(data.latestExportAt, isNull);
      expect(data.commentsSnapshot, isNull);
      expect(data.liveChatsSnapshot, isNull);
    });

    test('its summary names its channel without counts or a date', () {
      final summary = parseTakeoutSummary(
        'UCme',
        _summaryFiles(_withoutAppFiles),
      );

      expect(summary.channels.map((c) => c.channelId), ['UCme']);
      expect(summary.countsKnown, isFalse);
      expect(summary.latestExportAt, isNull);
    });
  });

  group('saved before channel counts', () {
    test('its export times, completeness and skipped rows load', () {
      final data = parseCsvFiles(_withoutChannelCounts);

      expect(data.comments, hasLength(2));
      expect(data.latestExportAt, DateTime.utc(2026, 2));
      expect(data.skippedCommentRows, 2);
      expect(
        data.commentsSnapshot,
        KindSnapshot(exportedAt: DateTime.utc(2026, 2), complete: true),
      );
      expect(data.liveChatsSnapshot, isNull);
    });

    test('its summary has its export date, but no counts', () {
      final summary = parseTakeoutSummary(
        'UCme',
        _summaryFiles(_withoutChannelCounts),
      );

      expect(summary.channels.map((c) => c.channelId), ['UCme']);
      expect(summary.latestExportAt, DateTime.utc(2026, 2));
      expect(summary.countsKnown, isFalse);
    });
  });

  test('an export times file missing later columns still loads', () {
    final data = parseCsvFiles({
      _comments: _commentsCsv,
      '_meta/takeout_meta.csv': _bytes(
        'Latest Export At,Skipped Comment Rows,Skipped Live Chat Rows\r\n'
        '2026-02-01T00:00:00.000Z,0,3\r\n',
      ),
    });

    expect(data.latestExportAt, DateTime.utc(2026, 2));
    expect(data.skippedLiveChatRows, 3);
    expect(data.commentsSnapshot, isNull);
    expect(data.liveChatsSnapshot, isNull);
  });
}
