import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/account_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import '../application/add_account_import.dart';
import '../application/saved_takeouts.dart';
import '../application/takeout_selection_notifier.dart';
import '../domain/takeout_channel.dart';
import 'add_account_section.dart';
import 'import_review.dart';
import 'leave_channel_screens.dart';
import 'takeout_details.dart';

/// [AddAccountSection] wired to [addAccountImportProvider]: imports a
/// takeout in place, as its own account or merged into its saved one, and
/// leaves screens tied to the channel shown before.
class ImportTakeout extends ConsumerWidget {
  /// The button's label before anything is picked.
  final String? idleLabel;

  /// Whether that button is the main thing to do, filled and centered.
  final bool prominent;

  /// Called once a takeout is saved and shown.
  final VoidCallback? onImported;

  const ImportTakeout({
    super.key,
    this.idleLabel,
    this.prominent = false,
    this.onImported,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final import = ref.read(addAccountImportProvider.notifier);
    final profiles = ref.watch(savedSignInsProvider).value ?? const {};
    return AddAccountSection(
      accounts: [
        for (final summary in ref.watch(savedTakeoutsProvider).value ?? [])
          _accountOf(summary, accountProfileFor(summary.channels, profiles)),
      ],
      onChooseAccount: import.chooseAccount,
      state: ref.watch(addAccountImportProvider),
      enabled:
          ref.watch(deletionProcessingProvider) == DeletionProcessingState.idle,
      idleLabel: idleLabel,
      prominent: prominent,
      // A first import is saved without a review when it needs none, and
      // one to merge shows the account it's for while it's reviewed.
      onStart: () => _whenShownChanges(context, ref, import.start),
      onConfirm: () => _whenShownChanges(context, ref, import.confirm),
      onDismiss: () {
        final router = StackRouterScope.of(context)?.controller;
        if (import.dismiss()) leaveChannelScreens(router);
      },
    );
  }

  static ImportAccount _accountOf(
    TakeoutSummary summary,
    SignInProfile? profile,
  ) => (
    takeoutId: summary.id,
    name: accountName(summary, profile),
    pictureUrl: accountPicture(summary, profile),
    details: describeTakeout(summary),
  );

  /// Runs [step], and once it has saved a takeout or shown another one,
  /// leaves screens tied to the channel shown before. Leaving closes a
  /// dialog opened over them, so while the import still shows something,
  /// such as a merge into the account shown for it, that waits for it to
  /// be dismissed.
  Future<void> _whenShownChanges(
    BuildContext context,
    WidgetRef ref,
    Future<bool> Function() step,
  ) async {
    final router = StackRouterScope.of(context)?.controller;
    String? shown() => ref.read(takeoutSelectionProvider).value?.takeoutId;
    final before = shown();
    final saved = await step();
    if (!context.mounted) return;
    final showing = ref.read(addAccountImportProvider) is! AddAccountIdle;
    if (saved || (shown() != before && !showing)) leaveChannelScreens(router);
    if (saved) onImported?.call();
  }
}
