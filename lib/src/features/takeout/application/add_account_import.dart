import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/zip_picker_repository.dart';
import '../domain/takeout_import_plan.dart';
import 'takeout_notifier.dart';

part 'add_account_import.g.dart';

/// Where adding another Google account's takeout is at.
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

/// Read and ready to be looked over before it's saved.
class AddAccountReview extends AddAccountState {
  final TakeoutImportPlan plan;

  const AddAccountReview(this.plan);
}

/// The takeout is from an account already saved, so nothing was imported.
class AddAccountAlreadySaved extends AddAccountState {
  final String takeoutId;

  const AddAccountAlreadySaved(this.takeoutId);
}

/// Reading or saving it failed. Nothing was imported.
class AddAccountFailed extends AddAccountState {
  final Object error;

  const AddAccountFailed(this.error);
}

/// Adds another Google account's takeout from the account dialog. Never
/// replaces or merges into an account already saved.
@riverpod
class AddAccountImport extends _$AddAccountImport {
  @override
  AddAccountState build() => const AddAccountIdle();

  /// Picks takeout zips and reads them for review.
  Future<void> start() async {
    // Straight from the click handler: see ZipPickerRepository.pickZips.
    final picked = await ref.read(zipPickerRepositoryProvider).pickZips();
    if (!ref.mounted || picked == null || picked.files.isEmpty) return;
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

  /// Saves the reviewed takeout as its own account and shows it.
  Future<void> confirm() async {
    if (state case AddAccountReview(:final plan)) {
      state = const AddAccountWorking();
      try {
        await ref.read(takeoutProvider.notifier).commitImport(plan);
        if (ref.mounted) state = const AddAccountIdle();
      } catch (e) {
        if (ref.mounted) state = AddAccountFailed(e);
      }
    }
  }

  void dismiss() => state = const AddAccountIdle();
}
