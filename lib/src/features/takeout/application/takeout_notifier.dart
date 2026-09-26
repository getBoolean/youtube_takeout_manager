import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/signed_in_channel_provider.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';

import '../data/takeout_import_planner.dart';
import '../data/takeout_import_service.dart';
import '../data/takeout_repository.dart';
import '../domain/loaded_takeout.dart';
import '../domain/takeout_channel.dart';
import '../domain/takeout_data.dart';
import '../domain/takeout_import_plan.dart';
import 'takeout_selection_notifier.dart';

part 'takeout_notifier.g.dart';

/// The selected saved takeout, with every channel's items. Reloads when
/// another takeout is selected.
@Riverpod(keepAlive: true)
class TakeoutNotifier extends _$TakeoutNotifier {
  /// Data an import just saved, so selecting its takeout needn't read and
  /// parse it again.
  LoadedTakeout? _primed;

  @override
  Future<LoadedTakeout?> build() async {
    // Notifier.ref is the latest build's, so keep this one's to tell if a
    // newer build has replaced it.
    final buildRef = ref;
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
    final loaded = LoadedTakeout(id: takeoutId, data: data);
    if (buildRef.mounted) await _assignQueueChannels(loaded);
    return loaded;
  }

  /// Fills in the channel of queued deletions saved before it was, from
  /// [loaded]'s authors. Items that aren't in it keep waiting for theirs.
  Future<void> _assignQueueChannels(LoadedTakeout loaded) async {
    // Read, not watched: the queue changing mustn't reload the takeout.
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

    return compute(planTakeoutImport, (
      zips: zips,
      saved: await _savedData(required: merge),
      merge: merge,
      signedInChannelId: await _signedInChannelId(),
      deletedCommentIds: await ref.read(deletedCommentIdsProvider.future),
      deletedLiveChatIds: await ref.read(deletedLiveChatIdsProvider.future),
    ));
  }

  /// Marks the items [plan] found gone as deleted and drops their pending
  /// deletions, then saves its data in its takeout's folder and selects that
  /// takeout.
  Future<void> commitImport(TakeoutImportPlan plan) async {
    // Gone items are gone whether or not the save below works, so mark them
    // first; otherwise a failed save would leave them deletable, and each
    // delete of a missing comment still costs quota.
    final queue = ref.read(deletionQueueProvider.notifier);
    if (plan.goneCommentIds.isNotEmpty) {
      await ref
          .read(deletedCommentIdsProvider.notifier)
          .markDeleted(plan.goneCommentIds);
      await queue.dropUnprocessed(plan.goneCommentIds, QueueItemKind.comment);
    }
    if (plan.goneLiveChatIds.isNotEmpty) {
      await ref
          .read(deletedLiveChatIdsProvider.notifier)
          .markDeleted(plan.goneLiveChatIds);
      await queue.dropUnprocessed(plan.goneLiveChatIds, QueueItemKind.liveChat);
    }

    await ref
        .read(takeoutRepositoryProvider)
        .saveCsvs(plan.accountId, plan.csvFiles);
    final loaded = LoadedTakeout(id: plan.accountId, data: plan.mergedData);
    await _assignQueueChannels(loaded);
    final selection = await ref.read(takeoutSelectionProvider.future);
    if (selection?.takeoutId == plan.accountId) {
      state = AsyncData(loaded);
      return;
    }
    // Selecting it rebuilds this, which picks up the data from here.
    _primed = loaded;
    await ref.read(takeoutSelectionProvider.notifier).select(plan.accountId);
    await future;
  }

  /// Whether [accountId] has takeout data saved, active or not.
  Future<bool> hasSavedData(String accountId) async =>
      await ref.read(takeoutRepositoryProvider).loadCsvs(accountId) != null;

  /// The saved data to merge with or compare against. When replacing, data
  /// that failed to load is ignored instead of blocking the import.
  Future<TakeoutData?> _savedData({required bool required}) async {
    try {
      return (await future)?.data;
    } catch (_) {
      if (required) rethrow;
      return null;
    }
  }

  Future<String?> _signedInChannelId() async {
    try {
      return await ref.read(signedInChannelIdProvider.future);
    } catch (e) {
      // Look it up again on the next attempt.
      ref.invalidate(signedInChannelIdProvider);
      throw TakeoutImportException(
        "Couldn't check which YouTube channel you're signed in with ($e). "
        'Try signing out and back in, or sign out to import without this '
        'check.',
      );
    }
  }
}
