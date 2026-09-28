import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_channel_assignment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_csv_codec.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_files.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';

import '../data/takeout_csv_encoder.dart';
import '../data/takeout_export_reader.dart';
import '../data/takeout_repository.dart';
import '../data/takeout_summary_parser.dart';
import '../domain/loaded_takeout.dart';
import '../domain/takeout_data.dart';
import '../domain/takeout_export.dart';
import '../domain/takeout_import_plan.dart';
import '../domain/takeout_import_planner.dart';
import '../domain/takeout_import_request.dart';
import 'takeout_notifier.dart';
import 'takeout_selection_notifier.dart';

part 'takeout_importer.g.dart';

/// A worked-out import and the CSV files that saving it writes, encoded
/// while the zips are read so committing only has to save them, and the
/// takeouts read from them, to plan again without reading them again.
typedef PreparedImport = ({
  TakeoutImportPlan plan,
  Map<String, Uint8List> csvFiles,
  List<TakeoutExport> exports,
});

/// Takeouts already read, to work out importing them.
typedef _PlanRequest = ({
  List<TakeoutExport> exports,
  TakeoutImportContext context,
  Map<String, Uint8List> savedHistoryFiles,
});

/// Top-level function for `compute` — reads the picked zips, works out what
/// importing them would change, and encodes the result for saving.
PreparedImport _readAndPlan(TakeoutImportRequest request) => _plan((
  exports: readTakeoutExports(request.zips),
  context: request.context,
  savedHistoryFiles: request.savedHistoryFiles,
));

/// Top-level function for `compute` — works out what importing takeouts
/// already read would change, and encodes the result for saving.
PreparedImport _plan(_PlanRequest request) {
  final exports = request.exports;
  final savedHistory = request.savedHistoryFiles;
  // Saved history is only read to merge picked history into it.
  final plan = planTakeoutImport(
    exports,
    request.context,
    savedHistory: exports.any((e) => e.history != null)
        ? parseSavedHistory(savedHistory)
        : null,
  );
  final mergedHistory = plan.history.merged;
  return (
    plan: plan,
    csvFiles: {
      ...encodeTakeoutCsvs(plan.mergedData),
      // Saving replaces every file, so history not merged is saved again.
      ...mergedHistory == null
          ? savedHistory
          : encodeHistoryCsvs(mergedHistory),
    },
    exports: exports,
  );
}

/// Imports takeouts: works out what picked zips would change, then saves
/// them, marking what they found gone. A service: nothing depends on it, so
/// it can read any provider.
@Riverpod(keepAlive: true)
class TakeoutImporter extends _$TakeoutImporter {
  @override
  void build() {}

  /// Reads the picked [zips] and works out what importing them would
  /// change, and encodes the files saving it writes, without saving
  /// anything. [merge] adds them to the saved data instead of replacing it.
  /// Throws a [TakeoutImportException] when they can't be imported safely.
  Future<PreparedImport> prepareImport(
    List<PickedZip> zips, {
    required bool merge,
  }) async {
    final (:context, :savedHistoryFiles) = await _planContext(merge: merge);
    return compute(_readAndPlan, (
      zips: zips,
      context: context,
      savedHistoryFiles: savedHistoryFiles,
    ));
  }

  /// Works out merging [exports], read by [prepareImport], into the takeout
  /// shown, without reading their zips again: e.g. once another account is
  /// shown to take them. Throws as [prepareImport] does.
  Future<PreparedImport> prepareMerge(List<TakeoutExport> exports) async {
    final (:context, :savedHistoryFiles) = await _planContext(merge: true);
    return compute(_plan, (
      exports: exports,
      context: context,
      savedHistoryFiles: savedHistoryFiles,
    ));
  }

  /// What planning an import needs from what's saved: [merge] adds to the
  /// takeout shown instead of replacing it.
  Future<
    ({TakeoutImportContext context, Map<String, Uint8List> savedHistoryFiles})
  >
  _planContext({required bool merge}) async {
    final saved = await _savedData(required: merge);
    final loaded = ref.read(takeoutProvider).value;
    final summaries = await loadTakeoutSummaries(
      ref.read(takeoutRepositoryProvider),
      loaded: loaded,
    );
    final deleted = await ref.read(deletedIdsProvider.future);
    final activeTakeoutId = await _selectedTakeoutId();
    final savedHistoryFiles = merge && activeTakeoutId != null
        ? await ref
              .read(takeoutRepositoryProvider)
              .loadCsvs(activeTakeoutId, only: isHistoryPath)
        : null;
    return (
      context: (
        saved: saved,
        savedChannelSets: {for (final s in summaries) s.id: s.channelIds},
        merge: merge,
        deletedCommentIds: deleted[QueueItemKind.comment] ?? const {},
        deletedLiveChatIds: deleted[QueueItemKind.liveChat] ?? const {},
        activeTakeoutId: activeTakeoutId,
      ),
      savedHistoryFiles: savedHistoryFiles ?? const <String, Uint8List>{},
    );
  }

  /// Marks the items [prepared]'s plan found gone as deleted and drops their
  /// pending deletions, then saves its files in its takeout's folder and
  /// selects that takeout.
  Future<void> commitImport(PreparedImport prepared) async {
    final (:plan, :csvFiles, exports: _) = prepared;
    if (await _selectedTakeoutId() != plan.baseTakeoutId) {
      throw const TakeoutImportException(
        'Another takeout was opened while this one was being read. Import '
        'it again.',
      );
    }
    // Gone items are gone whether or not the save below works, so mark them
    // first; otherwise a failed save would leave them deletable, and each
    // delete of a missing comment still costs quota.
    final gone = DeletionTargets.ids({
      QueueItemKind.comment: plan.goneCommentIds,
      QueueItemKind.liveChat: plan.goneLiveChatIds,
    });
    await ref.read(deletedIdsProvider.notifier).markDeleted(gone);
    final queue = ref.read(deletionQueueProvider.notifier);
    for (final kind in QueueItemKind.values) {
      final ids = gone.idsOf(kind);
      if (ids.isNotEmpty) await queue.dropUnprocessed(ids, kind);
    }

    await ref
        .read(takeoutRepositoryProvider)
        .saveCsvs(plan.accountId, csvFiles);
    // Reloaded from what was just saved when it's next looked at.
    ref.invalidate(takeoutHistoryProvider);
    final loaded = LoadedTakeout(id: plan.accountId, data: plan.mergedData);
    await ref.read(queueChannelAssignerProvider.notifier).assign(loaded);
    final takeout = ref.read(takeoutProvider.notifier);
    if (await _selectedTakeoutId() == plan.accountId) {
      takeout.show(loaded);
      return;
    }
    // Selecting it reloads the takeout, which picks up the data from here.
    takeout.prime(loaded);
    await ref.read(takeoutSelectionProvider.notifier).select(plan.accountId);
    await ref.read(takeoutProvider.future);
  }

  /// Whether [accountId] has takeout data saved, active or not.
  Future<bool> hasSavedData(String accountId) async =>
      (await ref.read(takeoutRepositoryProvider).listAccountIds()).contains(
        accountId,
      );

  /// The selected takeout, or null if there's none or the selection failed
  /// to load. An import then replaces it.
  Future<String?> _selectedTakeoutId() async {
    try {
      return (await ref.read(takeoutSelectionProvider.future))?.takeoutId;
    } catch (_) {
      return null;
    }
  }

  /// The saved data to merge with or compare against. When replacing, data
  /// that failed to load is ignored instead of blocking the import.
  Future<TakeoutData?> _savedData({required bool required}) async {
    try {
      return (await ref.read(takeoutProvider.future))?.data;
    } catch (_) {
      if (required) rethrow;
      return null;
    }
  }
}
