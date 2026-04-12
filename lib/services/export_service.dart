import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

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
      ['Type', 'ID', 'Channel ID', 'Channel Name', 'Video ID', 'Date', 'Text'],
      // Comments
      ...comments.map((c) => [
            'comment',
            c.commentId,
            c.channelId,
            channelNames?[c.channelId] ?? '',
            c.videoId ?? '',
            c.createdAt.toIso8601String(),
            c.displayText,
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
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Saves content to a file. Uses file picker save dialog on desktop,
  /// share sheet on mobile.
  Future<void> saveToFile(
    String content,
    String filename,
    ExportFormat format,
  ) async {
    final extension = format == ExportFormat.csv ? 'csv' : 'json';
    final fullFilename = '$filename.$extension';

    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile: use share sheet
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fullFilename');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)]);
    } else {
      // Desktop: use save dialog
      final result = await FilePicker.saveFile(
        fileName: fullFilename,
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      if (result != null) {
        await File(result).writeAsString(content);
      }
    }
  }
}
