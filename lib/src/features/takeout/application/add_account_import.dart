import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/zip_picker_repository.dart';
import '../domain/takeout_import_plan.dart';
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
  final TakeoutImportPlan plan;

  const AddAccountReview(this.plan);
}

/// The takeout is from an account already saved: nothing is imported unless
/// the user chooses to merge it into that account.
class AddAccountAlreadySaved extends AddAccountState {
  final String takeoutId;

  const AddAccountAlreadySaved(this.takeoutId);
}

/// Read for merging into its saved account, now shown, and ready to be
/// looked over before it's saved.
class AddAccountMergeReview extends AddAccountState {
  final TakeoutImportPlan plan;

  const AddAccountMergeReview(this.plan);
}

/// Reading or saving it failed. Nothing was imported.
class AddAccountFailed extends AddAccountState {
  final Object error;

  const AddAccountFailed(this.error);
}

/// Imports a takeout in place: as its own account, or merged into its saved
/// account only if the user says so. Nothing is ever replaced.
@riverpod
class AddAccountImport extends _$AddAccountImport {
  /// The zips picked, kept in case they're merged into a saved account.
  FilePickerResult? _picked;

  @override
  AddAccountState build() => const AddAccountIdle();

  /// Picks takeout zips and reads them for review. The first takeout saved
  /// skips the review when there's nothing in it to look over. Returns
  /// whether it was saved.
  Future<bool> start() async {
    // Straight from the click handler: see ZipPickerRepository.pickZips.
    final picked = await ref.read(zipPickerRepositoryProvider).pickZips();
    if (!ref.mounted || picked == null || picked.files.isEmpty) return false;
    _picked = picked;
    state = const AddAccountWorking();
    try {
      final takeouts = ref.read(takeoutImporterProvider.notifier);
      final plan = await takeouts.prepareImport(picked, merge: false);
      if (await takeouts.hasSavedData(plan.accountId)) {
        if (ref.mounted) state = AddAccountAlreadySaved(plan.accountId);
        return false;
      }
      final first = (await ref.read(savedTakeoutsProvider.future)).isEmpty;
      if (!ref.mounted) return false;
      if (first && !plan.needsReview) return await _save(plan);
      state = AddAccountReview(plan);
    } catch (e) {
      if (ref.mounted) state = AddAccountFailed(e);
    }
    return false;
  }

  /// Shows the saved account the picked takeout is from, since merging
  /// works on the takeout shown, and reads the takeout to merge into it.
  Future<void> merge() async {
    final picked = _picked;
    if (state case AddAccountAlreadySaved(
      :final takeoutId,
    ) when picked != null) {
      state = const AddAccountWorking();
      try {
        final selection = ref.read(takeoutSelectionProvider.notifier);
        final shown = (await ref.read(
          takeoutSelectionProvider.future,
        ))?.takeoutId;
        if (shown != takeoutId) await selection.select(takeoutId);
        await ref.read(takeoutProvider.future);
        final plan = await ref
            .read(takeoutImporterProvider.notifier)
            .prepareImport(picked, merge: true);
        if (ref.mounted) state = AddAccountMergeReview(plan);
      } catch (e) {
        if (ref.mounted) state = AddAccountFailed(e);
      }
    }
  }

  /// Saves the reviewed takeout, as its own account or merged into its
  /// saved one, and shows it. Returns whether it was saved.
  Future<bool> confirm() async {
    final plan = switch (state) {
      AddAccountReview(:final plan) ||
      AddAccountMergeReview(:final plan) => plan,
      _ => null,
    };
    if (plan == null) return false;
    return _save(plan);
  }

  Future<bool> _save(TakeoutImportPlan plan) async {
    state = const AddAccountWorking();
    try {
      await ref.read(takeoutImporterProvider.notifier).commitImport(plan);
      if (ref.mounted) dismiss();
      return true;
    } catch (e) {
      if (ref.mounted) state = AddAccountFailed(e);
      return false;
    }
  }

  void dismiss() {
    _picked = null;
    state = const AddAccountIdle();
  }
}
