import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/zip_picker_repository.dart';
import '../domain/takeout_import_plan.dart';
import 'takeout_notifier.dart';
import 'takeout_selection_notifier.dart';

part 'add_account_import.g.dart';

/// Where importing another Google account's takeout is at.
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

/// Imports another Google account's takeout from the account dialog. One
/// from an account already saved is merged into it only if the user says
/// so; nothing is ever replaced.
@riverpod
class AddAccountImport extends _$AddAccountImport {
  /// The zips picked, kept in case they're merged into a saved account.
  FilePickerResult? _picked;

  @override
  AddAccountState build() => const AddAccountIdle();

  /// Picks takeout zips and reads them for review.
  Future<void> start() async {
    // Straight from the click handler: see ZipPickerRepository.pickZips.
    final picked = await ref.read(zipPickerRepositoryProvider).pickZips();
    if (!ref.mounted || picked == null || picked.files.isEmpty) return;
    _picked = picked;
    state = const AddAccountWorking();
    try {
      final takeouts = ref.read(takeoutProvider.notifier);
      final plan = await takeouts.prepareImport(picked, merge: false);
      final saved = await takeouts.hasSavedData(plan.accountId);
      if (!ref.mounted) return;
      state = saved
          ? AddAccountAlreadySaved(plan.accountId)
          : AddAccountReview(plan);
    } catch (e) {
      if (ref.mounted) state = AddAccountFailed(e);
    }
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
            .read(takeoutProvider.notifier)
            .prepareImport(picked, merge: true);
        if (ref.mounted) state = AddAccountMergeReview(plan);
      } catch (e) {
        if (ref.mounted) state = AddAccountFailed(e);
      }
    }
  }

  /// Saves the reviewed takeout, as its own account or merged into its
  /// saved one, and shows it.
  Future<void> confirm() async {
    final plan = switch (state) {
      AddAccountReview(:final plan) ||
      AddAccountMergeReview(:final plan) => plan,
      _ => null,
    };
    if (plan == null) return;
    state = const AddAccountWorking();
    try {
      await ref.read(takeoutProvider.notifier).commitImport(plan);
      if (ref.mounted) dismiss();
    } catch (e) {
      if (ref.mounted) state = AddAccountFailed(e);
    }
  }

  void dismiss() {
    _picked = null;
    state = const AddAccountIdle();
  }
}
