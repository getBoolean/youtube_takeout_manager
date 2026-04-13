import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/takeout_data.dart';
import '../services/deletion_persistence_service.dart';
import '../services/takeout_import_service.dart';
import '../services/takeout_persistence_service.dart';

part 'takeout_providers.g.dart';

@Riverpod(keepAlive: true)
class TakeoutNotifier extends _$TakeoutNotifier {
  @override
  Future<TakeoutData?> build() async {
    final persistence = TakeoutPersistenceService();
    final savedCsvs = await persistence.loadCsvs();
    if (savedCsvs == null) return null;

    final data = await compute(parseCsvFiles, savedCsvs);
    return _filterDeleted(data);
  }

  /// Picks zip files, extracts CSVs, saves them to disk, and returns the
  /// parsed data. Returns true if data was imported, false if cancelled.
  Future<bool> importFiles() async {
    final service = TakeoutImportService();
    final result = await service.pickAndImport();
    if (result == null) return false;

    // Persist extracted CSVs for future sessions.
    await TakeoutPersistenceService().saveCsvs(result.csvFiles);

    state = AsyncData(await _filterDeleted(result.data));
    return true;
  }

  void removeComments(Set<String> commentIds) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      comments: current.comments
          .where((c) => !commentIds.contains(c.commentId))
          .toList(),
    ));
  }

  void removeLiveChats(Set<String> liveChatIds) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      liveChats: current.liveChats
          .where((c) => !liveChatIds.contains(c.liveChatId))
          .toList(),
    ));
  }

  Future<TakeoutData> _filterDeleted(TakeoutData data) async {
    final persistence = DeletionPersistenceService();
    final deletedCommentIds = await persistence.loadDeletedCommentIds();
    final deletedLiveChatIds = await persistence.loadDeletedLiveChatIds();

    return data.copyWith(
      comments: data.comments
          .where((c) => !deletedCommentIds.contains(c.commentId))
          .toList(),
      liveChats: data.liveChats
          .where((c) => !deletedLiveChatIds.contains(c.liveChatId))
          .toList(),
    );
  }
}
