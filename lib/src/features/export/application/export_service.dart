import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../data/export_file_repository.dart';
import '../domain/export_format.dart';

part 'export_service.g.dart';

@Riverpod(keepAlive: true)
ExportService exportService(Ref ref) =>
    ExportService(ref.watch(exportFileRepositoryProvider));

/// Service for exporting comments and live chats to CSV or JSON files.
class ExportService {
  static final _csv = Csv();

  final ExportFileRepository _files;

  ExportService(this._files);

  /// Writes [comments] and [liveChats] as [format] and saves them as
  /// [filename]. Returns `true` if the file was saved, `false` if the user
  /// cancelled.
  Future<bool> export({
    required List<Comment> comments,
    required List<LiveChat> liveChats,
    required ExportFormat format,
    required String filename,
    Map<String, String>? channelNames,
  }) {
    final content = switch (format) {
      ExportFormat.csv => exportToCsv(
        comments,
        liveChats,
        channelNames: channelNames,
      ),
      ExportFormat.json => exportToJson(
        comments,
        liveChats,
        channelNames: channelNames,
      ),
    };
    return _files.save(content, filename, format);
  }

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
      ...comments.map(
        (c) => [
          'comment',
          c.commentId,
          c.channelId,
          channelNames?[c.channelId] ?? '',
          c.videoId ?? '',
          c.createdAt.toIso8601String(),
          c.displayText,
          c.price,
          '',
        ],
      ),
      // Live chats
      ...liveChats.map(
        (c) => [
          'live_chat',
          c.liveChatId,
          c.channelId,
          channelNames?[c.channelId] ?? '',
          c.videoId ?? '',
          c.createdAt.toIso8601String(),
          c.displayText,
          c.price,
          c.currencyCode ?? '',
        ],
      ),
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
          .map(
            (c) => {
              'id': c.commentId,
              'channelId': c.channelId,
              'channelName': channelNames?[c.channelId],
              'videoId': c.videoId,
              'date': c.createdAt.toIso8601String(),
              'text': c.displayText,
              'parentCommentId': c.parentCommentId,
              'price': c.price,
            },
          )
          .toList(),
      'liveChats': liveChats
          .map(
            (c) => {
              'id': c.liveChatId,
              'channelId': c.channelId,
              'channelName': channelNames?[c.channelId],
              'videoId': c.videoId,
              'date': c.createdAt.toIso8601String(),
              'text': c.displayText,
              'price': c.price,
              'currency': c.currencyCode,
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Sanitizes a string for use as a filename.
  static String sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
}
