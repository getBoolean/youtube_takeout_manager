import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import '../domain/own_channel.dart';
import '../domain/subscription.dart';
import '../domain/takeout_import_plan.dart';

/// Result of parsing a CSV file, including diagnostic counts.
class CsvParseResult<T> {
  final List<T> items;

  /// Number of rows the CSV parser produced (excluding header).
  final int parsedRowCount;

  /// Number of rows skipped for having too few columns or an unreadable
  /// timestamp.
  final int skippedRowCount;

  const CsvParseResult({
    required this.items,
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

  /// Parses a comments CSV file into a list of [Comment] objects.
  ///
  /// Supports both 8-column (no Post ID) and 9-column (with Post ID) formats.
  CsvParseResult<Comment> parseCommentsCsv(Uint8List bytes) =>
      _parseRows(bytes, 'comments', (header) {
        final iId = header.required('Comment ID');
        final iChannel = header.required('Channel ID');
        final iTimestamp = header.required('Comment Create Timestamp', [
          'created at',
        ]);
        final iPrice = header.required('Price');
        final iParent = header.optional('parent comment id');
        final iPost = header.optional('post id');
        final iVideo = header.optional('video id');
        final iText = header.required('Comment Text');
        final iTopLevel = header.optional('top-level comment id');
        return (row) => switch (DateTime.tryParse(_str(row[iTimestamp]))) {
          final createdAt? => Comment(
            commentId: _str(row[iId]),
            channelId: _str(row[iChannel]),
            createdAt: createdAt,
            price: _toDouble(row[iPrice]),
            parentCommentId: _optional(row, iParent),
            postId: _optional(row, iPost),
            videoId: _optional(row, iVideo),
            rawCommentText: _str(row[iText]),
            displayText: parseCommentText(_str(row[iText])),
            topLevelCommentId: _optional(row, iTopLevel),
          ),
          null => null,
        };
      });

  /// Parses a live chats CSV file into a list of [LiveChat] objects.
  ///
  /// Supports 6, 7, and 8-column formats with varying presence of
  /// Currency Code and Parent Live Chat ID columns.
  CsvParseResult<LiveChat> parseLiveChatsCsv(Uint8List bytes) =>
      _parseRows(bytes, 'live chats', (header) {
        final iId = header.required('Live Chat ID');
        final iChannel = header.required('Channel ID');
        final iTimestamp = header.required('Live Chat Create Timestamp', [
          'created at',
        ]);
        final iPrice = header.required('Price');
        final iCurrency = header.optional('currency code');
        final iVideo = header.optional('video id');
        final iText = header.required('Live Chat Text', ['text']);
        return (row) => switch (DateTime.tryParse(_str(row[iTimestamp]))) {
          final createdAt? => LiveChat(
            liveChatId: _str(row[iId]),
            channelId: _str(row[iChannel]),
            createdAt: createdAt,
            price: _toDouble(row[iPrice]),
            currencyCode: _optional(row, iCurrency),
            videoId: _optional(row, iVideo),
            rawText: _str(row[iText]),
            displayText: parseCommentText(_str(row[iText])),
          ),
          null => null,
        };
      });

  /// Reads each data row of a [file] CSV with the reader [columns] makes
  /// from its header. Rows shorter than the header, or that the reader
  /// can't read (returning null), are skipped and counted.
  CsvParseResult<T> _parseRows<T>(
    Uint8List bytes,
    String file,
    T? Function(List<dynamic> row) Function(_Header header) columns,
  ) {
    final rows = _csv.decode(utf8.decode(bytes));
    if (rows.isEmpty) {
      return const CsvParseResult(
        items: [],
        parsedRowCount: 0,
        skippedRowCount: 0,
      );
    }

    final read = columns(_Header(rows.first, file));
    final minCols = rows.first.length;
    final dataRows = rows.skip(1).toList();
    final items = [
      for (final row in dataRows)
        if (row.length >= minCols) ?read(row),
    ];
    return CsvParseResult(
      items: items,
      parsedRowCount: dataRows.length,
      skippedRowCount: dataRows.length - items.length,
    );
  }

  /// Parses a subscriptions CSV file into a list of [Subscription] objects.
  List<Subscription> parseSubscriptionsCsv(Uint8List bytes) {
    final rows = _csv.decode(utf8.decode(bytes));
    if (rows.isEmpty) return [];
    final header = _Header(rows.first, 'subscriptions');
    var (iId, iUrl, iTitle) = (
      header.optional('channel id'),
      header.optional('channel url'),
      header.optional('channel title'),
    );
    // Takeouts in other languages may name none of the columns; those are
    // read in Google's order. Columns missing from a header that names some
    // are left empty.
    if (iId == null && iUrl == null && iTitle == null) {
      (iId, iUrl, iTitle) = (0, 1, 2);
    }
    final minCols = [iId, iUrl, iTitle].nonNulls.fold(0, max) + 1;
    return [
      for (final row in rows.skip(1))
        if (row.length >= minCols)
          Subscription(
            channelId: _optional(row, iId) ?? '',
            channelUrl: _optional(row, iUrl) ?? '',
            channelTitle: _optional(row, iTitle) ?? '',
          ),
    ];
  }

  /// Parses a takeout's `channels/channel.csv`: the account's channels and
  /// their titles. Takeout may list any number of them.
  List<OwnChannel> parseChannelsCsv(Uint8List bytes) {
    final rows = _csv.decode(utf8.decode(bytes));
    if (rows.isEmpty) return [];
    final header = _Header(rows.first, 'channel');
    final iId = header.optional('channel id');
    if (iId == null) return [];
    final iTitle = header.optional('channel title (original)', [
      'channel title',
    ]);
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
    final header = _Header(rows.first, 'channel URL configs');
    final iId = header.optional('channel id');
    final iName = header.optional('channel vanity url 1 name');
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

  /// The trimmed value at [index] in [row], or null when it's empty or the
  /// row is too short.
  static String? _field(List<dynamic> row, int? index) =>
      index != null && index < row.length ? _nullableStr(row[index]) : null;

  /// The trimmed value at [index] in [row], or null when it's empty or the
  /// file has no such column.
  static String? _optional(List<dynamic> row, int? index) =>
      index != null ? _nullableStr(row[index]) : null;

  static String _str(dynamic value) => value?.toString().trim() ?? '';

  static String? _nullableStr(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

/// A CSV file's header: where each column is, by name.
class _Header {
  /// Column index by lowercased, trimmed name.
  final Map<String, int> _index;

  /// What the file holds, for errors.
  final String _file;

  _Header(List<dynamic> row, this._file)
    : _index = {
        for (var i = 0; i < row.length; i++)
          row[i].toString().toLowerCase().trim(): i,
      };

  /// The index of the column called [name] or one of [otherNames], or null
  /// if there's none.
  int? optional(String name, [List<String> otherNames = const []]) {
    for (final n in [name, ...otherNames]) {
      if (_index[n.toLowerCase()] case final i?) return i;
    }
    return null;
  }

  /// The index of [column], which the file can't be read without, also
  /// trying [otherNames]. Throws when the header has none of them.
  int required(String column, [List<String> otherNames = const []]) =>
      optional(column, otherNames) ??
      (throw TakeoutImportException(
        "The takeout's $_file file has no \"$column\" column, so it "
        "couldn't be read. Google may have changed the takeout's format.",
      ));
}
