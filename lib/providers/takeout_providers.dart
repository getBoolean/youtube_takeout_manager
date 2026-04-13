import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/takeout_data.dart';
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

    return compute(parseCsvFiles, savedCsvs);
  }

  /// Picks zip files, extracts CSVs, saves them to disk, and returns the
  /// parsed data. Returns true if data was imported, false if cancelled.
  Future<bool> importFiles() async {
    final service = TakeoutImportService();
    final result = await service.pickAndImport();
    if (result == null) return false;

    // Persist extracted CSVs for future sessions.
    await TakeoutPersistenceService().saveCsvs(result.csvFiles);

    state = AsyncData(result.data);
    return true;
  }

  /// Force a rebuild so widgets watching this provider re-render
  /// (e.g. after deleted-IDs set changes).
  void notifyChanged() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current);
  }
}
