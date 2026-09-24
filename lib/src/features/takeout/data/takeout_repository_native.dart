import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'takeout_repository.dart';

class TakeoutRepositoryImpl implements TakeoutRepository {
  static const _dirName = 'takeout_csvs';

  Future<Directory> _getDir() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory('${appDir.path}/$_dirName');
  }

  @override
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

  @override
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
      final relativePath = p
          .relative(file.path, from: dir.path)
          .replaceAll('\\', '/');
      result[relativePath] = await file.readAsBytes();
    }
    return result;
  }

  @override
  Future<void> clearCsvs() async {
    final dir = await _getDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
