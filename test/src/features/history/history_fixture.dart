import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/history/data/history_csv_codec.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_engine.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';

/// [history] loaded as the app loads it: saved, then read by the History
/// engine (in-process in tests), so it can be searched and counted there.
Future<LoadedHistory> loadThroughEngine(
  Ref ref,
  TakeoutHistory history,
) async => LoadedHistory.fromRows(
  await ref.watch(historyEngineProvider).load(encodeHistoryCsvs(history)),
);
