import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../application/export_service.dart';
import '../domain/export_format.dart';

part 'export_controller.g.dart';

enum ExportResult { success, cancelled, error }

@riverpod
class ExportNotifier extends _$ExportNotifier {
  @override
  bool build() => false; // isExporting

  Future<ExportResult> exportData({
    required List<Comment> comments,
    required List<LiveChat> liveChats,
    required ExportFormat format,
    required String filename,
    Map<String, String>? channelNames,
  }) async {
    state = true;
    try {
      final service = ExportService();
      final content = switch (format) {
        ExportFormat.csv => service.exportToCsv(
          comments,
          liveChats,
          channelNames: channelNames,
        ),
        ExportFormat.json => service.exportToJson(
          comments,
          liveChats,
          channelNames: channelNames,
        ),
      };
      final saved = await service.saveToFile(content, filename, format);
      return saved ? ExportResult.success : ExportResult.cancelled;
    } catch (_) {
      return ExportResult.error;
    } finally {
      state = false;
    }
  }
}
