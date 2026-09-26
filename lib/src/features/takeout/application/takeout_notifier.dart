import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/takeout_import_service.dart';
import '../data/takeout_repository.dart';
import '../domain/loaded_takeout.dart';
import 'takeout_selection_notifier.dart';

part 'takeout_notifier.g.dart';

/// Retries a failed load twice (after 200ms, then 400ms) instead of
/// Riverpod's ten, in case the disk was busy. Saved data that can't be
/// parsed won't parse on a later try either, so the failure then shows
/// instead of loading for over half a minute.
Duration? _retryLoadBriefly(int retryCount, Object error) =>
    ProviderContainer.defaultRetry(retryCount, error, maxRetries: 2);

/// The selected saved takeout, with every channel's items. Reloads when
/// another takeout is selected. Importing is `TakeoutImporter`'s.
@Riverpod(keepAlive: true, retry: _retryLoadBriefly)
class TakeoutNotifier extends _$TakeoutNotifier {
  /// Data an import just saved, so selecting its takeout needn't read and
  /// parse it again.
  LoadedTakeout? _primed;

  @override
  Future<LoadedTakeout?> build() async {
    final repository = ref.watch(takeoutRepositoryProvider);
    final takeoutId = await ref.watch(
      takeoutSelectionProvider.selectAsync((s) => s?.takeoutId),
    );
    if (takeoutId == null) return null;

    if (_primed case final primed? when primed.id == takeoutId) {
      _primed = null;
      return primed;
    }
    final savedCsvs = await repository.loadCsvs(takeoutId);
    if (savedCsvs == null) return null;
    final data = await compute(parseCsvFiles, savedCsvs);
    return LoadedTakeout(id: takeoutId, data: data);
  }

  /// Hands over [loaded], just saved, for when its takeout is selected next,
  /// so it needn't be read and parsed again.
  void prime(LoadedTakeout loaded) => _primed = loaded;

  /// Shows [loaded], just saved for the takeout already selected.
  void show(LoadedTakeout loaded) => state = AsyncData(loaded);
}
