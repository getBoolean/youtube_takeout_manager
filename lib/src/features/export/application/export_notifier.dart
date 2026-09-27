import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../domain/export_format.dart';
import 'export_service.dart';

part 'export_notifier.g.dart';

enum ExportResult { success, cancelled, error }

/// Whether an export is running. Kept alive so an export outlives the
/// widget that started it.
@Riverpod(keepAlive: true)
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
      final saved = await ref
          .read(exportServiceProvider)
          .export(
            comments: comments,
            liveChats: liveChats,
            format: format,
            filename: filename,
            channelNames: channelNames,
          );
      return saved ? ExportResult.success : ExportResult.cancelled;
    } catch (_) {
      return ExportResult.error;
    } finally {
      state = false;
    }
  }
}
