import 'package:flutter/material.dart';

import '../domain/takeout_import_plan.dart';
import 'import_review.dart';

/// Shows what importing [plan] will change and asks before anything is saved.
/// Pops `true` to go ahead.
class ImportConfirmDialog extends StatelessWidget {
  final TakeoutImportPlan plan;

  /// Whether the takeout is added to the saved data instead of replacing it.
  final bool merge;

  /// Whether data is shown now.
  final bool hasSavedData;

  /// Whether the takeout's account already has saved data that replacing
  /// overwrites, even if it isn't the data shown now.
  final bool replacesSavedData;

  /// Whether the saved data failed to load, so it may be overwritten unseen.
  final bool savedDataUnreadable;

  const ImportConfirmDialog({
    super.key,
    required this.plan,
    required this.merge,
    required this.hasSavedData,
    this.replacesSavedData = false,
    this.savedDataUnreadable = false,
  });

  @override
  Widget build(BuildContext context) {
    final replacing = hasSavedData || replacesSavedData || savedDataUnreadable;
    final (title, action) = merge
        ? ('Add this takeout?', 'Add')
        : plan.differentAccount != null
        ? ('Import another channel?', 'Import')
        : replacing
        ? ('Replace your data?', 'Replace')
        : ('Import this takeout?', 'Import');

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: ImportReview(
          plan: plan,
          merge: merge,
          hasSavedData: hasSavedData,
          replacesSavedData: replacesSavedData,
          savedDataUnreadable: savedDataUnreadable,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    );
  }
}
