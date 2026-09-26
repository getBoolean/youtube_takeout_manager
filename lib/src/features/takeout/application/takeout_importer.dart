import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';

import '../data/takeout_import_planner.dart';
import '../data/takeout_repository.dart';
import '../data/takeout_summary_parser.dart';
import '../domain/loaded_takeout.dart';
import '../domain/takeout_channel.dart';
import '../domain/takeout_data.dart';
import '../domain/takeout_import_plan.dart';
import 'takeout_notifier.dart';
import 'takeout_selection_notifier.dart';

part 'takeout_importer.g.dart';

/// Imports takeouts: works out what picked zips would change, then saves
/// them, marking what they found gone. A service: nothing depends on it, so
/// it can read any provider.
@Riverpod(keepAlive: true)
class TakeoutImporter extends _$TakeoutImporter {
  @override
  void build() {}

  /// Reads the picked zips and works out what importing them would change,
  /// without saving anything. [merge] adds them to the saved data instead of
  /// replacing it. Throws a [TakeoutImportException] when they can't be
  /// imported safely.
  Future<TakeoutImportPlan> prepareImport(
    FilePickerResult picked, {
    required bool merge,
  }) async {
    final zips = <PickedZip>[];
    for (final file in picked.files) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw TakeoutImportException('Couldn\'t read "${file.name}".');
      }
      zips.add((name: file.name, bytes: bytes));
    }

    final saved = await _savedData(required: merge);
    final loaded = ref.read(takeoutProvider).value;
    final summaries = await loadTakeoutSummaries(
      ref.read(takeoutRepositoryProvider),
      loaded: loaded,
    );
    final deleted = await ref.read(deletedIdsProvider.future);
    return compute(planTakeoutImport, (
      zips: zips,
      saved: saved,
      savedChannelSets: {for (final s in summaries) s.id: s.channelIds},
      merge: merge,
      deletedCommentIds: deleted[QueueItemKind.comment] ?? const {},
      deletedLiveChatIds: deleted[QueueItemKind.liveChat] ?? const {},
      activeTakeoutId: await _selectedTakeoutId(),
    ));
  }

  /// Marks the items [plan] found gone as deleted and drops their pending
  /// deletions, then saves its data in its takeout's folder and selects that
  /// takeout.
  Future<void> commitImport(TakeoutImportPlan plan) async {
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
        .saveCsvs(plan.accountId, plan.csvFiles);
    final loaded = LoadedTakeout(id: plan.accountId, data: plan.mergedData);
    await assignQueueChannels(loaded);
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

  /// Fills in the channel of queued deletions saved before it was, from
  /// [loaded]'s authors. Items that aren't in it keep waiting for theirs.
  Future<void> assignQueueChannels(LoadedTakeout loaded) async {
    final queue = ref.read(deletionQueueProvider.notifier);
    final items = await ref.read(deletionQueueProvider.future);
    final missing = {
      for (final i in items)
        if (i.authorChannelId == null) i.itemId,
    };
    if (missing.isEmpty) return;

    final main = takeoutChannelsOf(loaded.data, takeoutId: loaded.id).first;
    String author(String channelId) =>
        channelId.isEmpty ? main.channelId : channelId;
    await queue.assignMissingChannels(
      commentAuthors: {
        for (final c in loaded.data.comments)
          if (missing.contains(c.commentId)) c.commentId: author(c.channelId),
      },
      liveChatAuthors: {
        for (final l in loaded.data.liveChats)
          if (missing.contains(l.liveChatId)) l.liveChatId: author(l.channelId),
      },
    );
  }

  /// The selected takeout, or null if there's none or the selection failed
  /// to load, e.g. saved data no channel wrote. An import then replaces it.
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

/// Fills in the channel of queued deletions saved before it was, each time
/// a takeout loads. An effect, started with the app.
@Riverpod(keepAlive: true)
void queueChannelAssignment(Ref ref) {
  ref.listen(takeoutProvider, (previous, next) {
    if (next case AsyncData(
      value: final loaded?,
    ) when !identical(loaded, previous?.value)) {
      unawaited(
        ref.read(takeoutImporterProvider.notifier).assignQueueChannels(loaded),
      );
    }
  }, fireImmediately: true);
}
