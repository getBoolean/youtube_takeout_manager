import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_repository.dart';

/// Saved takeouts kept in memory, for tests.
class MemoryTakeoutRepository implements TakeoutRepository {
  final accounts = <String, Map<String, Uint8List>>{};

  /// Every path [loadCsvs] has returned.
  final loadedPaths = <String>[];
  Map<String, Uint8List>? legacy;

  /// Holds up loading [legacy] until it completes.
  Completer<void>? legacyGate;
  bool failSaves = false;

  @override
  Future<void> saveCsvs(
    String accountId,
    Map<String, Uint8List> csvFiles,
  ) async {
    if (failSaves) throw const FileSystemException('disk full');
    accounts[accountId] = {...csvFiles};
  }

  @override
  Future<Map<String, Uint8List>?> loadCsvs(
    String accountId, {
    bool Function(String path)? only,
  }) async {
    final files = accounts[accountId];
    if (files == null) return null;
    final loaded = {
      for (final MapEntry(:key, :value) in files.entries)
        if (only?.call(key) ?? true) key: value,
    };
    loadedPaths.addAll(loaded.keys);
    return loaded;
  }

  @override
  Future<List<String>> listAccountIds() async => accounts.keys.toList();

  @override
  Future<void> clearCsvs(String accountId) async => accounts.remove(accountId);

  @override
  Future<Map<String, Uint8List>?> loadLegacyCsvs() async {
    await legacyGate?.future;
    return legacy;
  }

  @override
  Future<void> clearLegacyCsvs() async => legacy = null;
}
