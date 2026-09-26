import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import '../application/add_account_import.dart';
import 'import_error_dialog.dart';
import 'import_review.dart';

/// Adds another Google account's takeout in place: a button, then progress,
/// a review to confirm, or why nothing was imported.
class AddAccountSection extends StatelessWidget {
  final AddAccountState state;

  /// Whether one can be added now, i.e. nothing is being deleted through
  /// the YouTube API.
  final bool enabled;

  /// Saved accounts' names by takeout ID, to name one already saved.
  final Map<String, String> accountNames;
  final String? viewedTakeoutId;

  final VoidCallback onStart;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  /// Views the saved account a takeout turned out to be from.
  final ValueChanged<String> onViewSaved;

  const AddAccountSection({
    super.key,
    required this.state,
    required this.enabled,
    required this.accountNames,
    required this.viewedTakeoutId,
    required this.onStart,
    required this.onConfirm,
    required this.onDismiss,
    required this.onViewSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (state) {
      AddAccountIdle() => Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          onPressed: enabled ? onStart : null,
          icon: isTinyWidth(context) ? null : const Icon(Icons.add),
          label: const Text(
            'Add another Google account',
            textAlign: TextAlign.center,
          ),
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
        title: 'Add this Google account?',
        error: false,
        actions: [
          TextButton(
            onPressed: onDismiss,
            child: const Text('Cancel', textAlign: TextAlign.center),
          ),
          FilledButton(
            onPressed: enabled ? onConfirm : null,
            child: const Text('Add account', textAlign: TextAlign.center),
          ),
        ],
        children: [ImportReview(plan: plan, merge: false, newAccount: true)],
      ),
      AddAccountAlreadySaved(:final takeoutId) => _alreadySaved(takeoutId),
      AddAccountFailed(:final error) => NoticeBanner(
        title: importErrorTitle(error),
        onDismiss: onDismiss,
        children: [ImportErrorDetails(error: error)],
      ),
    };
  }

  Widget _alreadySaved(String takeoutId) {
    final name = accountNames[takeoutId] ?? takeoutId;
    final viewing = takeoutId == viewedTakeoutId;
    return NoticeBanner(
      title: 'Account already saved',
      onDismiss: onDismiss,
      actions: [
        if (!viewing)
          TextButton(
            onPressed: enabled ? () => onViewSaved(takeoutId) : null,
            child: Text('View $name', textAlign: TextAlign.center),
          ),
      ],
      children: [
        Text(
          'This takeout is from $name, which is already saved'
          "${viewing ? " (it's the one shown)" : ''}. Nothing was imported. "
          'To update it, use Add Newer Takeout on Home while viewing it.',
        ),
      ],
    );
  }
}
