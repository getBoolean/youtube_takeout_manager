import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'takeout_repository.dart';

/// Stores each account's files in `<app support>/takeouts/<account ID>/`.
class TakeoutRepositoryImpl implements TakeoutRepository {
  static const _dirName = 'takeouts';

  /// Where files were saved before they were kept per account.
  static const _legacyDirName = 'takeout_csvs';

  final Future<Directory> Function() _supportDirectory;

  TakeoutRepositoryImpl({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  Future<Directory> _accountDir(String accountId) async {
    checkAccountId(accountId);
    final appDir = await _supportDirectory();
    return Directory('${appDir.path}/$_dirName/$accountId');
  }

  Future<Directory> _legacyDir() async {
    final appDir = await _supportDirectory();
    return Directory('${appDir.path}/$_legacyDirName');
  }

  @override
  Future<void> saveCsvs(
    String accountId,
    Map<String, Uint8List> csvFiles,
  ) async {
    final dir = await _accountDir(accountId);
    final tmp = Directory('${dir.path}.tmp');
    final old = Directory('${dir.path}.old');

    // Write everything before touching the saved files, then swap with
    // renames, so an interrupted save never leaves only part of the data.
    await _deleteIfExists(tmp);
    for (final entry in csvFiles.entries) {
      final file = File('${tmp.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }

    await _deleteIfExists(old);
    if (await dir.exists()) await dir.rename(old.path);
    await tmp.rename(dir.path);
    await _deleteIfExists(old);
  }

  @override
  Future<Map<String, Uint8List>?> loadCsvs(String accountId) async {
    final dir = await _accountDir(accountId);
    await _finishInterruptedSave(dir);
    return _loadDir(dir);
  }

  @override
  Future<void> clearCsvs(String accountId) async {
    final dir = await _accountDir(accountId);
    for (final path in [dir.path, '${dir.path}.tmp', '${dir.path}.old']) {
      await _deleteIfExists(Directory(path));
    }
  }

  @override
  Future<Map<String, Uint8List>?> loadLegacyCsvs() async =>
      _loadDir(await _legacyDir());

  @override
  Future<void> clearLegacyCsvs() async => _deleteIfExists(await _legacyDir());

  Future<Map<String, Uint8List>?> _loadDir(Directory dir) async {
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

  /// A save that stopped after moving the old files aside has fully written
  /// the new files, so move them into place.
  Future<void> _finishInterruptedSave(Directory dir) async {
    if (await dir.exists()) return;
    final tmp = Directory('${dir.path}.tmp');
    final old = Directory('${dir.path}.old');
    if (await tmp.exists() && await old.exists()) {
      await tmp.rename(dir.path);
      await _deleteIfExists(old);
    }
  }

  Future<void> _deleteIfExists(Directory dir) async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
