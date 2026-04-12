import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../models/comment.dart';
import '../models/live_chat.dart';
import '../models/subscription.dart';
import '../utils/comment_text_parser.dart';

/// Parses Google Takeout CSV files into model objects.
class CsvParserService {
  static final _csv = Csv();

  /// Parses a comments CSV file into a list of [Comment] objects.
  List<Comment> parseCommentsCsv(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final rows = _csv.decode(content);
    if (rows.isEmpty) return [];

    // Skip header row
    return rows.skip(1).where((row) => row.length >= 9).map((row) {
      final rawText = _str(row[7]);
      return Comment(
        commentId: _str(row[0]),
        channelId: _str(row[1]),
        createdAt: DateTime.parse(_str(row[2])),
        price: _toDouble(row[3]),
        parentCommentId: _nullableStr(row[4]),
        postId: _nullableStr(row[5]),
        videoId: _nullableStr(row[6]),
        rawCommentText: rawText,
        displayText: parseCommentText(rawText),
        topLevelCommentId: _nullableStr(row[8]),
      );
    }).toList();
  }

  /// Parses a live chats CSV file into a list of [LiveChat] objects.
  List<LiveChat> parseLiveChatsCsv(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final rows = _csv.decode(content);
    if (rows.isEmpty) return [];

    // Skip header row
    return rows.skip(1).where((row) => row.length >= 7).map((row) {
      final rawText = _str(row[6]);
      return LiveChat(
        liveChatId: _str(row[0]),
        channelId: _str(row[1]),
        createdAt: DateTime.parse(_str(row[2])),
        price: _toDouble(row[3]),
        currencyCode: _nullableStr(row[4]),
        videoId: _nullableStr(row[5]),
        rawText: rawText,
        displayText: parseCommentText(rawText),
      );
    }).toList();
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
