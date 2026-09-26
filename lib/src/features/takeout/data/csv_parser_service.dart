import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import '../domain/own_channel.dart';
import '../domain/subscription.dart';
import '../domain/takeout_data.dart';

/// Result of parsing a CSV file, including diagnostic counts.
class CsvParseResult<T> {
  final List<T> items;

  /// Number of non-empty lines in the raw file (including header).
  final int rawLineCount;

  /// Number of rows the CSV parser produced (excluding header).
  final int parsedRowCount;

  /// Number of rows skipped due to insufficient columns.
  final int skippedRowCount;

  const CsvParseResult({
    required this.items,
    required this.rawLineCount,
    required this.parsedRowCount,
    required this.skippedRowCount,
  });
}

/// Parses Google Takeout CSV files into model objects.
///
/// Google Takeout uses varying CSV formats across different export batches
/// within the same zip. Column presence differs (e.g. Post ID, Currency Code,
/// Parent Live Chat ID may or may not be present). This parser builds a column
/// index map from each file's header to handle all variants.
class CsvParserService {
  static final _csv = Csv(autoDetect: false);

  /// Builds a map of normalized column name -> column index from a header row.
  static Map<String, int> _buildColumnIndex(List<dynamic> header) {
    final index = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      index[header[i].toString().toLowerCase().trim()] = i;
    }
    return index;
  }

  /// Finds the column index for a field, trying multiple possible header names.
  static int? _col(Map<String, int> index, List<String> names) {
    for (final name in names) {
      final i = index[name.toLowerCase()];
      if (i != null) return i;
    }
    return null;
  }

  /// Parses a comments CSV file into a list of [Comment] objects.
  ///
  /// Supports both 8-column (no Post ID) and 9-column (with Post ID) formats.
  CsvParseResult<Comment> parseCommentsCsv(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final rawLineCount = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;
    final rows = _csv.decode(content);
    if (rows.isEmpty) {
      return const CsvParseResult(
        items: [],
        rawLineCount: 0,
        parsedRowCount: 0,
        skippedRowCount: 0,
      );
    }

    final cols = _buildColumnIndex(rows.first);
    final iId = _col(cols, ['comment id'])!;
    final iChannel = _col(cols, ['channel id'])!;
    final iTimestamp = _col(cols, ['comment create timestamp', 'created at'])!;
    final iPrice = _col(cols, ['price'])!;
    final iParent = _col(cols, ['parent comment id']);
    final iPost = _col(cols, ['post id']);
    final iVideo = _col(cols, ['video id']);
    final iText = _col(cols, ['comment text'])!;
    final iTopLevel = _col(cols, ['top-level comment id']);
    final minCols = rows.first.length;

    final dataRows = rows.skip(1).toList();
    final valid = dataRows.where((row) => row.length >= minCols).toList();
    final skipped = dataRows.length - valid.length;

    return CsvParseResult(
      items: valid.map((row) {
        final rawText = _str(row[iText]);
        return Comment(
          commentId: _str(row[iId]),
          channelId: _str(row[iChannel]),
          createdAt: DateTime.parse(_str(row[iTimestamp])),
          price: _toDouble(row[iPrice]),
          parentCommentId: iParent != null ? _nullableStr(row[iParent]) : null,
          postId: iPost != null ? _nullableStr(row[iPost]) : null,
          videoId: iVideo != null ? _nullableStr(row[iVideo]) : null,
          rawCommentText: rawText,
          displayText: parseCommentText(rawText),
          topLevelCommentId: iTopLevel != null
              ? _nullableStr(row[iTopLevel])
              : null,
        );
      }).toList(),
      rawLineCount: rawLineCount,
      parsedRowCount: dataRows.length,
      skippedRowCount: skipped,
    );
  }

  /// Parses a live chats CSV file into a list of [LiveChat] objects.
  ///
  /// Supports 6, 7, and 8-column formats with varying presence of
  /// Currency Code and Parent Live Chat ID columns.
  CsvParseResult<LiveChat> parseLiveChatsCsv(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final rawLineCount = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;
    final rows = _csv.decode(content);
    if (rows.isEmpty) {
      return const CsvParseResult(
        items: [],
        rawLineCount: 0,
        parsedRowCount: 0,
        skippedRowCount: 0,
      );
    }

    final cols = _buildColumnIndex(rows.first);
    final iId = _col(cols, ['live chat id'])!;
    final iChannel = _col(cols, ['channel id'])!;
    final iTimestamp = _col(cols, [
      'live chat create timestamp',
      'created at',
    ])!;
    final iPrice = _col(cols, ['price'])!;
    final iCurrency = _col(cols, ['currency code']);
    final iVideo = _col(cols, ['video id']);
    final iText = _col(cols, ['live chat text', 'text'])!;
    final minCols = rows.first.length;

    final dataRows = rows.skip(1).toList();
    final valid = dataRows.where((row) => row.length >= minCols).toList();
    final skipped = dataRows.length - valid.length;

    return CsvParseResult(
      items: valid.map((row) {
        final rawText = _str(row[iText]);
        return LiveChat(
          liveChatId: _str(row[iId]),
          channelId: _str(row[iChannel]),
          createdAt: DateTime.parse(_str(row[iTimestamp])),
          price: _toDouble(row[iPrice]),
          currencyCode: iCurrency != null ? _nullableStr(row[iCurrency]) : null,
          videoId: iVideo != null ? _nullableStr(row[iVideo]) : null,
          rawText: rawText,
          displayText: parseCommentText(rawText),
        );
      }).toList(),
      rawLineCount: rawLineCount,
      parsedRowCount: dataRows.length,
      skippedRowCount: skipped,
    );
  }

  /// Parses a subscriptions CSV file into a list of [Subscription] objects.
  List<Subscription> parseSubscriptionsCsv(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final rows = _csv.decode(content);
    if (rows.isEmpty) return [];

    // Skip header row
    return rows.skip(1).where((row) => row.length >= 3).map((row) {
      return Subscription(
        channelId: _str(row[0]),
        channelUrl: _str(row[1]),
        channelTitle: _str(row[2]),
      );
    }).toList();
  }

  /// Parses a takeout's `channels/channel.csv`: the account's channels and
  /// their titles. Takeout may list any number of them.
  List<OwnChannel> parseChannelsCsv(Uint8List bytes) {
    final rows = _csv.decode(utf8.decode(bytes));
    if (rows.isEmpty) return [];
    final cols = _buildColumnIndex(rows.first);
    final iId = _col(cols, ['channel id']);
    if (iId == null) return [];
    final iTitle = _col(cols, ['channel title (original)', 'channel title']);
    return [
      for (final row in rows.skip(1))
        if (_field(row, iId) case final id?)
          OwnChannel(channelId: id, title: _field(row, iTitle)),
    ];
  }

  /// Parses a takeout's `channels/channel URL configs.csv` into each
  /// channel's vanity URL name, by channel ID.
  Map<String, String> parseChannelUrlConfigsCsv(Uint8List bytes) {
    final rows = _csv.decode(utf8.decode(bytes));
    if (rows.isEmpty) return {};
    final cols = _buildColumnIndex(rows.first);
    final iId = _col(cols, ['channel id']);
    final iName = _col(cols, ['channel vanity url 1 name']);
    if (iId == null || iName == null) return {};
    return {
      for (final row in rows.skip(1))
        if ((_field(row, iId), _field(row, iName)) case (
          final id?,
          final name?,
        ))
          id: name,
    };
  }

  /// Parses the per-channel counts written by [encodeTakeoutCsvs]: comments
  /// and live chats by author channel ID, '' for rows without one.
  Map<String, ({int comments, int liveChats})> parseChannelCountsCsv(
    Uint8List bytes,
  ) {
    final rows = _csv.decode(utf8.decode(bytes));
    if (rows.isEmpty) return {};
    final cols = _buildColumnIndex(rows.first);
    final iId = _col(cols, ['channel id']);
    final iComments = _col(cols, ['comments']);
    final iLiveChats = _col(cols, ['live chats']);
    if (iId == null) return {};
    return {
      for (final row in rows.skip(1))
        if (row.length > iId)
          _str(row[iId]): (
            comments: _toDouble(_field(row, iComments)).toInt(),
            liveChats: _toDouble(_field(row, iLiveChats)).toInt(),
          ),
    };
  }

  /// Parses the meta file written by [encodeTakeoutCsvs].
  ({
    DateTime? latestExportAt,
    int skippedCommentRows,
    int skippedLiveChatRows,
    KindSnapshot? commentsSnapshot,
    KindSnapshot? liveChatsSnapshot,
  })
  parseMetaCsv(Uint8List bytes) {
    final rows = _csv.decode(utf8.decode(bytes));
    if (rows.length < 2) {
      return (
        latestExportAt: null,
        skippedCommentRows: 0,
        skippedLiveChatRows: 0,
        commentsSnapshot: null,
        liveChatsSnapshot: null,
      );
    }
    final cols = _buildColumnIndex(rows.first);
    final row = rows[1];
    String? field(String name) {
      final i = _col(cols, [name]);
      return i != null ? _nullableStr(row[i]) : null;
    }

    DateTime? time(String name) => switch (field(name)) {
      final value? => DateTime.parse(value),
      null => null,
    };
    int count(String name) => _toDouble(field(name)).toInt();
    KindSnapshot? snapshot(String kind) => switch (time('$kind exported at')) {
      final exportedAt? => KindSnapshot(
        exportedAt: exportedAt,
        complete: field('$kind complete') == 'true',
      ),
      null => null,
    };

    return (
      latestExportAt: time('latest export at'),
      skippedCommentRows: count('skipped comment rows'),
      skippedLiveChatRows: count('skipped live chat rows'),
      commentsSnapshot: snapshot('comments'),
      liveChatsSnapshot: snapshot('live chats'),
    );
  }

  /// The trimmed value at [index] in [row], or null when it's empty or the
  /// row is too short.
  String? _field(List<dynamic> row, int? index) =>
      index != null && index < row.length ? _nullableStr(row[index]) : null;

  String _str(dynamic value) => value?.toString().trim() ?? '';

  String? _nullableStr(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
