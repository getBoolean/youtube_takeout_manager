import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/signed_in_channel_provider.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import '../data/takeout_account_repository.dart';
import '../data/takeout_import_planner.dart';
import '../data/takeout_import_service.dart';
import '../data/takeout_repository.dart';
import '../domain/channel_id.dart';
import '../domain/takeout_data.dart';
import '../domain/takeout_import_plan.dart';

part 'takeout_notifier.g.dart';

@Riverpod(keepAlive: true)
class TakeoutNotifier extends _$TakeoutNotifier {
  @override
  Future<TakeoutData?> build() async {
    final repository = ref.watch(takeoutRepositoryProvider);
    final accounts = ref.watch(takeoutAccountRepositoryProvider);

    final accountId = await accounts.loadActiveAccountId();
    if (accountId == null) return _moveLegacyCsvs(repository, accounts);

    final savedCsvs = await repository.loadCsvs(accountId);
    if (savedCsvs == null) return null;
    return compute(parseCsvFiles, savedCsvs);
  }

  /// Moves CSVs saved before takeouts were kept per account into the folder
  /// of the channel that wrote most of them, and makes it the active account.
  Future<TakeoutData?> _moveLegacyCsvs(
    TakeoutRepository repository,
    TakeoutAccountRepository accounts,
  ) async {
    final legacyCsvs = await repository.loadLegacyCsvs();
    if (legacyCsvs == null) return null;

    final data = await compute(parseCsvFiles, legacyCsvs);
    final accountId = mostCommonAuthorChannelId(data);
    // Without a usable channel ID there's no account to move them to.
    if (accountId == null || !isChannelId(accountId)) return data;

    await repository.saveCsvs(accountId, legacyCsvs);
    await accounts.saveActiveAccountId(accountId);
    await repository.clearLegacyCsvs();
    return data;
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
  /// deletions, then saves its data in its account's folder and makes that
  /// the active account.
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
    await ref
        .read(takeoutAccountRepositoryProvider)
        .saveActiveAccountId(plan.accountId);
    state = AsyncData(plan.mergedData);
  }

  /// Whether [accountId] has takeout data saved, active or not.
  Future<bool> hasSavedData(String accountId) async =>
      await ref.read(takeoutRepositoryProvider).loadCsvs(accountId) != null;

  /// The saved data to merge with or compare against. When replacing, data
  /// that failed to load is ignored instead of blocking the import.
  Future<TakeoutData?> _savedData({required bool required}) async {
    try {
      return await future;
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

  /// Force a rebuild so widgets watching this provider re-render
  /// (e.g. after deleted-IDs set changes).
  void notifyChanged() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current);
  }
}
