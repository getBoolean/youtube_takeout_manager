import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import '../application/add_account_import.dart';
import 'import_error_details.dart';
import 'import_review.dart';

/// Imports a takeout in place: a button, then progress, a review to confirm
/// as its own account or as a merge into one already imported, or why
/// nothing was imported.
class AddAccountSection extends StatelessWidget {
  final AddAccountState state;

  /// The button's label before anything is picked.
  final String? idleLabel;

  /// Whether that button is the main thing to do, filled and centered.
  final bool prominent;

  /// Whether one can be imported now, i.e. nothing is being deleted through
  /// the YouTube API.
  final bool enabled;

  /// The saved accounts a takeout that names none can go into.
  final List<ImportAccount> accounts;

  final VoidCallback onStart;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  /// Puts a takeout that names no account into another saved account.
  final ValueChanged<String>? onChooseAccount;

  const AddAccountSection({
    super.key,
    required this.state,
    this.idleLabel,
    this.prominent = false,
    required this.enabled,
    this.accounts = const [],
    required this.onStart,
    required this.onConfirm,
    required this.onDismiss,
    this.onChooseAccount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = Text(
      idleLabel ?? 'Import a takeout',
      textAlign: TextAlign.center,
    );
    return switch (state) {
      AddAccountIdle() when prominent => Center(
        child: FilledButton.icon(
          onPressed: enabled ? onStart : null,
          icon: isTinyWidth(context) ? null : const Icon(Icons.folder_open),
          label: label,
        ),
      ),
      AddAccountIdle() => Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          onPressed: enabled ? onStart : null,
          icon: isTinyWidth(context) ? null : const Icon(Icons.add),
          label: label,
        ),
      ),
      AddAccountWorking() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reading the takeout…',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      AddAccountReview(:final plan) => NoticeBanner(
        key: const ValueKey('add-account-review'),
        title: 'Import this takeout?',
        error: false,
        actions: [
          TextButton(
            onPressed: onDismiss,
            child: const Text('Cancel', textAlign: TextAlign.center),
          ),
          FilledButton(
            onPressed: enabled ? onConfirm : null,
            child: const Text('Import', textAlign: TextAlign.center),
          ),
        ],
        children: [ImportReview(plan: plan, merge: false)],
      ),
      AddAccountMergeReview(:final plan, :final choosing) => NoticeBanner(
        key: const ValueKey('add-account-merge-review'),
        title: 'Merge this takeout?',
        error: false,
        actions: [
          TextButton(
            onPressed: onDismiss,
            child: const Text('Cancel', textAlign: TextAlign.center),
          ),
          FilledButton(
            // Not before the account being picked is worked out.
            onPressed: enabled && choosing == null ? onConfirm : null,
            child: const Text('Merge', textAlign: TextAlign.center),
          ),
        ],
        children: [
          ImportReview(
            plan: plan,
            merge: true,
            accounts: accounts,
            choosingAccount: choosing,
            // Switching accounts waits for deletion, and for the last pick.
            onChooseAccount: enabled && choosing == null
                ? onChooseAccount
                : null,
          ),
        ],
      ),
      AddAccountFailed(:final error) => NoticeBanner(
        key: const ValueKey('add-account-failed'),
        title: importErrorTitle(error),
        onDismiss: onDismiss,
        children: [ImportErrorDetails(error: error)],
      ),
    };
  }
}
