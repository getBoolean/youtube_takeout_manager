import 'dart:typed_data';

import 'takeout_persistence_service_stub.dart'
    if (dart.library.io) 'takeout_persistence_service_native.dart'
    if (dart.library.js_interop) 'takeout_persistence_service_web.dart'
    as platform;

/// Saves and loads extracted takeout CSV files to/from persistent storage
/// so users don't need to re-import on every launch.
///
/// Platform-specific implementations:
/// - Native (Windows/macOS/Linux): file-based storage via path_provider
/// - Web: no-op (data lives in memory for the session only)
abstract class TakeoutPersistenceService {
  factory TakeoutPersistenceService() = platform.TakeoutPersistenceServiceImpl;

  /// Saves extracted CSV files, preserving their relative paths.
  Future<void> saveCsvs(Map<String, Uint8List> csvFiles);

  /// Loads previously saved CSV files. Returns null if none exist.
  Future<Map<String, Uint8List>?> loadCsvs();

  /// Deletes all saved CSV files.
  Future<void> clearCsvs();
}
