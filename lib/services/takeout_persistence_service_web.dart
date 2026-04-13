import 'dart:typed_data';

import 'takeout_persistence_service.dart';

/// Web implementation: no-op persistence.
///
/// CSV data lives in the Riverpod provider state (keepAlive: true) for the
/// duration of the browser session. Re-import is needed after closing the tab.
class TakeoutPersistenceServiceImpl implements TakeoutPersistenceService {
  @override
  Future<void> saveCsvs(Map<String, Uint8List> csvFiles) async {}

  @override
  Future<Map<String, Uint8List>?> loadCsvs() async => null;

  @override
  Future<void> clearCsvs() async {}
}
