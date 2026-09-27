import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../application/export_notifier.dart';
import '../application/export_service.dart';
import '../domain/export_format.dart';

/// Asks whether to export as CSV or JSON. Returns the pick, or null if the
/// sheet was dismissed.
Future<ExportFormat?> showExportFormatSheet(BuildContext context) {
  return showModalBottomSheet<ExportFormat>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Export Data',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export as CSV'),
            subtitle: Text(
              'Comma-separated values (.${ExportFormat.csv.extension})',
            ),
            onTap: () => Navigator.pop(context, ExportFormat.csv),
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('Export as JSON'),
            subtitle: Text('Structured data (.${ExportFormat.json.extension})'),
            onTap: () => Navigator.pop(context, ExportFormat.json),
          ),
        ],
      ),
    ),
  );
}

/// Saves [comments] and [liveChats] from [channelName]'s channel as [format],
/// and says in a snack bar whether it worked.
Future<void> exportChannel(
  BuildContext context,
  WidgetRef ref, {
  required ExportFormat format,
  required String channelId,
  required String channelName,
  required List<Comment> comments,
  required List<LiveChat> liveChats,
}) async {
  final filename = ExportService.sanitizeFilename('${channelName}_export');
  final result = await ref
      .read(exportProvider.notifier)
      .exportData(
        comments: comments,
        liveChats: liveChats,
        format: format,
        filename: filename,
        channelNames: {channelId: channelName},
      );

  if (!context.mounted) return;

  switch (result) {
    case ExportResult.success:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported $filename.${format.extension}')),
      );
    case ExportResult.error:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export failed')));
    case ExportResult.cancelled:
      break;
  }
}
