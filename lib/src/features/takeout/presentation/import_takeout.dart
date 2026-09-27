import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import '../application/add_account_import.dart';
import '../application/saved_takeouts.dart';
import '../application/takeout_selection_notifier.dart';
import 'add_account_section.dart';
import 'leave_channel_screens.dart';

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
    final saved = ref.watch(savedTakeoutsProvider).value ?? const [];
    final import = ref.read(addAccountImportProvider.notifier);
    return AddAccountSection(
      state: ref.watch(addAccountImportProvider),
      enabled:
          ref.watch(deletionProcessingProvider) == DeletionProcessingState.idle,
      idleLabel: idleLabel,
      prominent: prominent,
      accountNames: {for (final t in saved) t.id: t.main.displayName},
      viewedTakeoutId: ref.watch(
        takeoutSelectionProvider.select((s) => s.value?.takeoutId),
      ),
      // A first import is saved without a review when it needs none.
      onStart: () => _whenImported(context, import.start),
      onConfirm: () => _whenImported(context, import.confirm),
      onDismiss: import.dismiss,
      // Merging shows the account it's for; the review stays open here.
      onMerge: () => leaveChannelScreensAfter(context, import.merge),
    );
  }

  /// Runs [step], and once it has saved a takeout, leaves screens tied to
  /// the channel shown before.
  Future<void> _whenImported(
    BuildContext context,
    Future<bool> Function() step,
  ) async {
    final router = StackRouterScope.of(context)?.controller;
    if (await step() && context.mounted) {
      leaveChannelScreens(router);
      onImported?.call();
    }
  }
}
