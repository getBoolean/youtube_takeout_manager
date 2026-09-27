import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../domain/takeout_data.dart';
import 'takeout_files.dart';

/// What [TakeoutFile.meta] holds: what a takeout's CSVs can't.
typedef TakeoutMeta = ({
  DateTime? latestExportAt,
  int skippedCommentRows,
  int skippedLiveChatRows,
  KindSnapshot? commentsSnapshot,
  KindSnapshot? liveChatsSnapshot,
});

final _csv = Csv(autoDetect: false);

/// Encodes [data]'s export times and skipped row counts as
/// [TakeoutFile.meta], for [decodeTakeoutMeta].
Uint8List encodeTakeoutMeta(TakeoutData data) => _encode([
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
]);

/// Reads a [TakeoutFile.meta] written by [encodeTakeoutMeta].
TakeoutMeta decodeTakeoutMeta(Uint8List bytes) {
  final meta = _records(bytes).firstOrNull ?? const {};
  String? field(String name) => switch (meta[name]) {
    final value? when value.isNotEmpty => value,
    _ => null,
  };
  DateTime? time(String name) => switch (field(name)) {
    final value? => DateTime.parse(value),
    null => null,
  };
  KindSnapshot? snapshot(String kind) => switch (time('$kind exported at')) {
    final exportedAt? => KindSnapshot(
      exportedAt: exportedAt,
      complete: field('$kind complete') == 'true',
    ),
    null => null,
  };

  return (
    latestExportAt: time('latest export at'),
    skippedCommentRows: _count(field('skipped comment rows')),
    skippedLiveChatRows: _count(field('skipped live chat rows')),
    commentsSnapshot: snapshot('comments'),
    liveChatsSnapshot: snapshot('live chats'),
  );
}

/// Encodes how many comments and live chats each channel wrote, by author
/// channel ID ('' for rows without one), as [TakeoutFile.channelCounts].
Uint8List encodeChannelCounts(Map<String, ItemCounts> counts) => _encode([
  ['Channel ID', 'Comments', 'Live Chats'],
  for (final MapEntry(key: id, value: n) in counts.entries)
    [id, n.comments, n.liveChats],
]);

/// Reads a [TakeoutFile.channelCounts] written by [encodeChannelCounts].
Map<String, ItemCounts> decodeChannelCounts(Uint8List bytes) => {
  for (final record in _records(bytes))
    ?record['channel id']: (
      comments: _count(record['comments']),
      liveChats: _count(record['live chats']),
    ),
};

/// [bytes]' rows after the header, each field by its lowercased column
/// name. Fields past the end of a short row are left out.
List<Map<String, String>> _records(Uint8List bytes) {
  final rows = _csv.decode(utf8.decode(bytes));
  if (rows.isEmpty) return const [];
  final header = [
    for (final name in rows.first) name.toString().toLowerCase().trim(),
  ];
  return [
    for (final row in rows.skip(1))
      {
        for (var i = 0; i < header.length && i < row.length; i++)
          header[i]: row[i]?.toString().trim() ?? '',
      },
  ];
}

int _count(String? value) => double.tryParse(value ?? '')?.toInt() ?? 0;

String _optionalTimestamp(DateTime? t) =>
    t != null ? t.toUtc().toIso8601String() : '';

Uint8List _encode(List<List<Object>> rows) =>
    Uint8List.fromList(utf8.encode(_csv.encode(rows)));
