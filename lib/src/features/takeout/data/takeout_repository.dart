import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/channel_id.dart';
import 'takeout_repository_stub.dart'
    if (dart.library.io) 'takeout_repository_native.dart'
    if (dart.library.js_interop) 'takeout_repository_web.dart'
    as platform;

part 'takeout_repository.g.dart';

@Riverpod(keepAlive: true)
TakeoutRepository takeoutRepository(Ref ref) => TakeoutRepository();

/// Saves and loads extracted takeout CSV files to/from persistent storage
/// so users don't need to re-import on every launch. Each YouTube account's
/// files are kept apart, keyed by its channel ID.
///
/// Platform-specific implementations:
/// - Native (Windows/macOS/Linux): file-based storage via path_provider
/// - Web: IndexedDB
abstract class TakeoutRepository {
  factory TakeoutRepository() = platform.TakeoutRepositoryImpl;

  /// Replaces the CSV files saved for [accountId], preserving their relative
  /// paths. If saving fails, the previously saved files are kept.
  Future<void> saveCsvs(String accountId, Map<String, Uint8List> csvFiles);

  /// Loads the CSV files saved for [accountId], or only those whose path
  /// [only] accepts. Returns null if none exist.
  Future<Map<String, Uint8List>?> loadCsvs(
    String accountId, {
    bool Function(String path)? only,
  });

  /// The IDs of every account with saved files.
  Future<List<String>> listAccountIds();

  /// Deletes the CSV files saved for [accountId].
  Future<void> clearCsvs(String accountId);

  /// Loads CSV files saved before they were kept per account. Returns null
  /// if none exist.
  Future<Map<String, Uint8List>?> loadLegacyCsvs();

  /// Deletes the CSV files saved before they were kept per account.
  Future<void> clearLegacyCsvs();
}

/// Rejects account IDs that aren't safe as a folder name or key prefix.
void checkAccountId(String accountId) {
  if (!isChannelId(accountId)) {
    throw ArgumentError.value(accountId, 'accountId', 'Not a channel ID');
  }
}
