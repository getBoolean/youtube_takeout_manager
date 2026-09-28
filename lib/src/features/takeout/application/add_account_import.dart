import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/zip_picker_repository.dart';
import '../domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'saved_takeouts.dart';
import 'takeout_importer.dart';
import 'takeout_notifier.dart';
import 'takeout_selection_notifier.dart';

part 'add_account_import.g.dart';

/// Where importing a takeout is at.
sealed class AddAccountState {
  const AddAccountState();
}

class AddAccountIdle extends AddAccountState {
  const AddAccountIdle();
}

/// Reading the picked zips, or saving them.
class AddAccountWorking extends AddAccountState {
  const AddAccountWorking();
}

/// Read and ready to be looked over before it's saved as its own account.
class AddAccountReview extends AddAccountState {
  final PreparedImport prepared;

  const AddAccountReview(this.prepared);

  TakeoutImportPlan get plan => prepared.plan;
}

/// From an account already saved, so read for merging into it, now shown,
/// and ready to be looked over before it's saved.
class AddAccountMergeReview extends AddAccountState {
  final PreparedImport prepared;

  /// For a takeout that names no account, the account picked for it
  /// instead, while that's shown and merging into it is worked out.
  final String? choosing;

  const AddAccountMergeReview(this.prepared, {this.choosing});

  TakeoutImportPlan get plan => prepared.plan;
}

/// Reading or saving it failed. Nothing was imported.
class AddAccountFailed extends AddAccountState {
  final Object error;

  const AddAccountFailed(this.error);
}

/// Imports a takeout in place: as its own account, or merged into its saved
/// account. Either is looked over before it's saved; nothing is ever
/// replaced.
@riverpod
class AddAccountImport extends _$AddAccountImport {
  /// The takeout shown when [start] began, to tell whether another has
  /// been shown since, to merge into it.
  String? _shownAtStart;

  @override
  AddAccountState build() => const AddAccountIdle();

  /// Picks takeout zips and reads them for review. One from an account
  /// already saved is reviewed as a merge into it, showing that account
  /// first, since merging works on the takeout shown. The first takeout
  /// saved skips the review when there's nothing in it to look over.
  /// Returns whether it was saved.
  Future<bool> start() async {
    _shownAtStart = ref.read(takeoutSelectionProvider).value?.takeoutId;
    try {
      // Straight from the click handler: see ZipPickerRepository.pickZips.
      final picked = await ref.read(zipPickerRepositoryProvider).pickZips();
      if (!ref.mounted || picked == null || picked.isEmpty) return false;
      state = const AddAccountWorking();
      final takeouts = ref.read(takeoutImporterProvider.notifier);
      final prepared = await takeouts.prepareImport(picked, merge: false);
      final plan = prepared.plan;
      if (await takeouts.hasSavedData(plan.accountId)) {
        await _reviewMerge(prepared, plan.accountId);
        return false;
      }
      final first = (await ref.read(savedTakeoutsProvider.future)).isEmpty;
      if (!ref.mounted) return false;
      if (first && !plan.needsReview) return await _save(prepared);
      state = AddAccountReview(prepared);
    } catch (e) {
      if (ref.mounted) state = AddAccountFailed(e);
    }
    return false;
  }

  /// Shows [takeoutId], the saved account [prepared]'s takeouts are from,
  /// and works out merging them into it, without reading them again.
  Future<void> _reviewMerge(PreparedImport prepared, String takeoutId) async {
    final selection = ref.read(takeoutSelectionProvider.notifier);
    final shown = (await ref.read(takeoutSelectionProvider.future))?.takeoutId;
    if (shown != takeoutId) await selection.select(takeoutId);
    await ref.read(takeoutProvider.future);
    final merge = await ref
        .read(takeoutImporterProvider.notifier)
        .prepareMerge(prepared.exports);
    if (!ref.mounted) return;
    // Named in the review once fetched.
    ref.read(extraVideoIdsProvider.notifier).set(merge.plan.newItemVideoIds);
    state = AddAccountMergeReview(merge);
  }

  /// Saves the reviewed takeout, as its own account or merged into its
  /// saved one, and shows it. Returns whether it was saved.
  Future<bool> confirm() async {
    final prepared = switch (state) {
      AddAccountReview(:final prepared) ||
      AddAccountMergeReview(:final prepared, choosing: null) => prepared,
      _ => null,
    };
    if (prepared == null) return false;
    return _save(prepared);
  }

  /// Puts the takeout in review, one that names no account, into
  /// [takeoutId]'s account instead: shows that account, since merging works
  /// on the takeout shown, then works out merging into it without reading
  /// the zips again. Dismissing the review meanwhile ends it.
  Future<void> chooseAccount(String takeoutId) async {
    if (state case AddAccountMergeReview(:final prepared, choosing: null)) {
      state = AddAccountMergeReview(prepared, choosing: takeoutId);
      bool stillChoosing() =>
          ref.mounted &&
          switch (state) {
            AddAccountMergeReview(:final choosing) => choosing == takeoutId,
            _ => false,
          };
      try {
        await ref.read(takeoutSelectionProvider.notifier).select(takeoutId);
        if (!stillChoosing()) return;
        await ref.read(takeoutProvider.future);
        if (!stillChoosing()) return;
        final merge = await ref
            .read(takeoutImporterProvider.notifier)
            .prepareMerge(prepared.exports);
        if (!stillChoosing()) return;
        // Named in the review once fetched.
        ref
            .read(extraVideoIdsProvider.notifier)
            .set(merge.plan.newItemVideoIds);
        state = AddAccountMergeReview(merge);
      } catch (e) {
        if (stillChoosing()) state = AddAccountFailed(e);
      }
    }
  }

  Future<bool> _save(PreparedImport prepared) async {
    ref.read(extraVideoIdsProvider.notifier).clear();
    state = const AddAccountWorking();
    try {
      await ref.read(takeoutImporterProvider.notifier).commitImport(prepared);
      if (ref.mounted) dismiss();
      return true;
    } catch (e) {
      if (ref.mounted) state = AddAccountFailed(e);
      return false;
    }
  }

  /// Ends the import, saved or not. Returns whether another takeout was
  /// shown meanwhile, to merge into it, which stays shown.
  bool dismiss() {
    // One being picked is shown as soon as it's selected, if it isn't yet.
    final choosing = switch (state) {
      AddAccountMergeReview(:final choosing) => choosing,
      _ => null,
    };
    ref.read(extraVideoIdsProvider.notifier).clear();
    state = const AddAccountIdle();
    final shown =
        choosing ?? ref.read(takeoutSelectionProvider).value?.takeoutId;
    return shown != _shownAtStart;
  }
}
