import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/comment.dart';
import '../models/export_format.dart';
import '../models/live_chat.dart';
import '../services/export_service.dart';

part 'export_providers.g.dart';

@riverpod
class ExportNotifier extends _$ExportNotifier {
  @override
  bool build() => false; // isExporting

  Future<void> exportData({
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
        ExportFormat.csv =>
          service.exportToCsv(comments, liveChats, channelNames: channelNames),
        ExportFormat.json =>
          service.exportToJson(comments, liveChats, channelNames: channelNames),
      };
      await service.saveToFile(content, filename, format);
    } finally {
      state = false;
    }
  }
}
