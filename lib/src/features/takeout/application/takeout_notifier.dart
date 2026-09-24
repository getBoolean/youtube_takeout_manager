import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/takeout_import_service.dart';
import '../data/takeout_persistence_service.dart';
import '../domain/takeout_data.dart';

part 'takeout_notifier.g.dart';

@Riverpod(keepAlive: true)
class TakeoutNotifier extends _$TakeoutNotifier {
  @override
  Future<TakeoutData?> build() async {
    final persistence = TakeoutPersistenceService();
    final savedCsvs = await persistence.loadCsvs();
    if (savedCsvs == null) return null;

    return compute(parseCsvFiles, savedCsvs);
  }

  /// Processes already-picked files: extracts CSVs, saves them to disk,
  /// and returns the parsed data. Returns true if data was imported.
  Future<bool> importPickedFiles(FilePickerResult pickerResult) async {
    final zipBytesList = <Uint8List>[];
    for (final file in pickerResult.files) {
      if (file.bytes != null) {
        zipBytesList.add(file.bytes!);
      }
    }
    if (zipBytesList.isEmpty) return false;

    final service = TakeoutImportService();
    final result = await service.importFromPickedBytes(zipBytesList);

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
