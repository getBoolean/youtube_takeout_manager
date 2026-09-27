import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_repository.dart';
import '../data/history_csv_codec.dart';
import '../data/history_files.dart';
import '../domain/takeout_history.dart';

part 'takeout_history_notifier.g.dart';

/// Retries a failed load twice, as the takeout's own load does: saved
/// history that can't be parsed won't parse on a later try either.
Duration? _retryLoadBriefly(int retryCount, Object error) =>
    ProviderContainer.defaultRetry(retryCount, error, maxRetries: 2);

/// The selected takeout's watch and search history, or null when no
/// takeout is selected. Loaded apart from the takeout, when first looked
/// at; an import that saves new history invalidates it.
@Riverpod(keepAlive: true, retry: _retryLoadBriefly)
class TakeoutHistoryNotifier extends _$TakeoutHistoryNotifier {
  @override
  Future<TakeoutHistory?> build() async {
    final repository = ref.watch(takeoutRepositoryProvider);
    final takeoutId = await ref.watch(
      takeoutSelectionProvider.selectAsync((s) => s?.takeoutId),
    );
    if (takeoutId == null) return null;
    final files = await repository.loadCsvs(takeoutId, only: isHistoryPath);
    if (files == null || files.isEmpty) return TakeoutHistory.empty;
    return compute(parseSavedHistory, files);
  }
}
