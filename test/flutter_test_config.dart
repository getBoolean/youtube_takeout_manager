import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/data/history_engine.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';

/// Runs before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // The app keeps bulk data in a worker; tests keep it in memory, fresh
  // for each test, as SharedPreferences' mock does.
  setUp(setMockStorage);
  // The history too is kept in-process.
  setLocalHistoryEngine();
  await testMain();
}
