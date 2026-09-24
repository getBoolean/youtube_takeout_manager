import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/comments/model/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/model/live_chat.dart';
import '../model/export_format.dart';
import '../service/export_service.dart';
import 'export_controller.dart';

/// Offers CSV or JSON export of [comments] and [liveChats] and saves the file.
void showExportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String channelId,
  required String channelName,
  required List<Comment> comments,
  required List<LiveChat> liveChats,
}) {
  final filename = ExportService.sanitizeFilename('${channelName}_export');
  final channelNames = {channelId: channelName};

  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Export Data',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export as CSV'),
            subtitle: const Text('Comma-separated values (.csv)'),
            onTap: () {
              Navigator.pop(ctx);
              _doExport(
                context,
                ref,
                format: ExportFormat.csv,
                filename: filename,
                comments: comments,
                liveChats: liveChats,
                channelNames: channelNames,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('Export as JSON'),
            subtitle: const Text('Structured data (.json)'),
            onTap: () {
              Navigator.pop(ctx);
              _doExport(
                context,
                ref,
                format: ExportFormat.json,
                filename: filename,
                comments: comments,
                liveChats: liveChats,
                channelNames: channelNames,
              );
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _doExport(
  BuildContext context,
  WidgetRef ref, {
  required ExportFormat format,
  required String filename,
  required List<Comment> comments,
  required List<LiveChat> liveChats,
  required Map<String, String> channelNames,
}) async {
  final ext = format == ExportFormat.csv ? 'csv' : 'json';
  final result = await ref
      .read(exportProvider.notifier)
      .exportData(
        comments: comments,
        liveChats: liveChats,
        format: format,
        filename: filename,
        channelNames: channelNames,
      );

  if (!context.mounted) return;

  switch (result) {
    case ExportResult.success:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported $filename.$ext')));
    case ExportResult.error:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export failed')));
    case ExportResult.cancelled:
      break;
  }
}
