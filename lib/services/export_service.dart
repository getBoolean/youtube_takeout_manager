import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

import '../models/comment.dart';
import '../models/export_format.dart';
import '../models/live_chat.dart';

/// Service for exporting comments and live chats to CSV or JSON files.
class ExportService {
  static final _csv = Csv();

  /// Generates a CSV string from comments and live chats.
  String exportToCsv(
    List<Comment> comments,
    List<LiveChat> liveChats, {
    Map<String, String>? channelNames,
  }) {
    final rows = <List<dynamic>>[
      // Header
      [
        'Type',
        'ID',
        'Channel ID',
        'Channel Name',
        'Video ID',
        'Date',
        'Text',
        'Price',
        'Currency',
      ],
      // Comments
      ...comments.map((c) => [
            'comment',
            c.commentId,
            c.channelId,
            channelNames?[c.channelId] ?? '',
            c.videoId ?? '',
            c.createdAt.toIso8601String(),
            c.displayText,
            c.price,
            '',
          ]),
      // Live chats
      ...liveChats.map((c) => [
            'live_chat',
            c.liveChatId,
            c.channelId,
            channelNames?[c.channelId] ?? '',
            c.videoId ?? '',
            c.createdAt.toIso8601String(),
            c.displayText,
            c.price,
            c.currencyCode ?? '',
          ]),
    ];

    return _csv.encode(rows);
  }

  /// Generates a JSON string from comments and live chats.
  String exportToJson(
    List<Comment> comments,
    List<LiveChat> liveChats, {
    Map<String, String>? channelNames,
  }) {
    final data = {
      'comments': comments
          .map((c) => {
                'id': c.commentId,
                'channelId': c.channelId,
                'channelName': channelNames?[c.channelId],
                'videoId': c.videoId,
                'date': c.createdAt.toIso8601String(),
                'text': c.displayText,
                'parentCommentId': c.parentCommentId,
                'price': c.price,
              })
          .toList(),
      'liveChats': liveChats
          .map((c) => {
                'id': c.liveChatId,
                'channelId': c.channelId,
                'channelName': channelNames?[c.channelId],
                'videoId': c.videoId,
                'date': c.createdAt.toIso8601String(),
                'text': c.displayText,
                'price': c.price,
                'currency': c.currencyCode,
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Saves content to a file using the platform-appropriate mechanism.
  /// Returns `true` if the file was saved, `false` if the user cancelled.
  Future<bool> saveToFile(
    String content,
    String filename,
    ExportFormat format,
  ) async {
    final ext = format == ExportFormat.csv ? 'csv' : 'json';
    final mimeType = format == ExportFormat.csv
        ? MimeType.csv
        : MimeType.json;
    final bytes = Uint8List.fromList(utf8.encode(content));

    if (kIsWeb) {
      final result = await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        fileExtension: ext,
        mimeType: mimeType,
      );
      return result.isNotEmpty;
    }

    final result = await FileSaver.instance.saveAs(
      name: filename,
      bytes: bytes,
      fileExtension: ext,
      mimeType: mimeType,
    );

    return result != null;
  }

  /// Sanitizes a string for use as a filename.
  static String sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
}
