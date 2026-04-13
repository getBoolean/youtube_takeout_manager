import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves and loads extracted takeout CSV files to/from the app's data
/// directory so users don't need to re-import on every launch.
class TakeoutPersistenceService {
  static const _dirName = 'takeout_csvs';

  Future<Directory> _getDir() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory('${appDir.path}/$_dirName');
  }

  /// Saves extracted CSV files to disk, preserving their relative paths
  /// so the existing path-matching logic in the parser works unchanged.
  Future<void> saveCsvs(Map<String, Uint8List> csvFiles) async {
    final dir = await _getDir();

    // Clear any previous data first.
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    for (final entry in csvFiles.entries) {
      final file = File('${dir.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
  }

  /// Loads previously saved CSV files. Returns null if none exist.
  ///
  /// Keys are the relative paths from the storage root, matching the original
  /// paths from the zip extraction (e.g. "Takeout/.../comments/comments.csv").
  Future<Map<String, Uint8List>?> loadCsvs() async {
    final dir = await _getDir();
    if (!await dir.exists()) return null;

    final files = await dir
        .list(recursive: true)
        .where((e) => e is File && e.path.endsWith('.csv'))
        .toList();
    if (files.isEmpty) return null;

    final result = <String, Uint8List>{};
    for (final entity in files) {
      final file = entity as File;
      // Build the relative path from the storage root.
      final relativePath =
          p.relative(file.path, from: dir.path).replaceAll('\\', '/');
      result[relativePath] = await file.readAsBytes();
    }
    return result;
  }

  /// Deletes all saved CSV files.
  Future<void> clearCsvs() async {
    final dir = await _getDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
