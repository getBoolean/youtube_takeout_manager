import 'package:flutter/material.dart';

import '../domain/takeout_import_plan.dart';

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
    final theme = Theme.of(context);
    final data = plan.mergedData;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.differentAccount case final mismatch?) ...[
              _Notice(
                icon: Icons.warning_amber_outlined,
                color: theme.colorScheme.error,
                text: _differentAccountNotice(mismatch),
              ),
              const SizedBox(height: 16),
            ],
            if (merge) ...[
              _Line(
                Icons.comment_outlined,
                _count(plan.newCommentCount, 'new comment'),
              ),
              _Line(
                Icons.chat_bubble_outline,
                _count(plan.newLiveChatCount, 'new live chat'),
              ),
            ] else ...[
              _Line(
                Icons.comment_outlined,
                _count(data.comments.length, 'comment'),
              ),
              _Line(
                Icons.chat_bubble_outline,
                _count(data.liveChats.length, 'live chat'),
              ),
            ],
            if (plan.newlyDeletedCommentCount > 0 ||
                plan.newlyDeletedLiveChatCount > 0) ...[
              const SizedBox(height: 16),
              Text('No longer on YouTube', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              if (plan.newlyDeletedCommentCount > 0)
                _Line(
                  Icons.delete_outline,
                  '${_count(plan.newlyDeletedCommentCount, 'comment')} will '
                  'be marked deleted',
                ),
              if (plan.newlyDeletedLiveChatCount > 0)
                _Line(
                  Icons.delete_outline,
                  '${_count(plan.newlyDeletedLiveChatCount, 'live chat')} '
                  'will be marked deleted',
                ),
            ],
            for (final warning in _warnings()) ...[
              const SizedBox(height: 12),
              _Notice(
                icon: Icons.info_outline,
                color: theme.colorScheme.tertiary,
                text: warning,
              ),
            ],
            if (savedDataUnreadable) ...[
              const SizedBox(height: 16),
              Text(
                "Your saved data couldn't be loaded. If it's from the same "
                'channel as this takeout, it will be replaced.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (!merge &&
                (hasSavedData || replacesSavedData) &&
                plan.differentAccount == null) ...[
              const SizedBox(height: 16),
              Text(
                'Comments and live chats that are only in your current data, '
                'including deleted ones, will be removed from the app.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
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

  String _differentAccountNotice(ChannelMismatch mismatch) {
    final found = mismatch.foundChannelIds.join(', ');
    final current = mismatch.expectedChannelIds.join(', ');
    final saved = replacesSavedData
        ? 'It replaces the data already saved for $found, including deleted '
              'items only saved there, and is shown instead.'
        : "It'll be saved separately and shown instead.";
    return 'This takeout is from a different YouTube channel ($found) than '
        'your current data ($current). $saved Your current data stays saved.';
  }

  List<String> _warnings() {
    String? warning(
      DeletionCheckSkipReason? reason,
      int skippedRows,
      String item,
    ) {
      final items = '${item}s';
      final unreadRows = skippedRows > 0
          ? "${_count(skippedRows, '$item row')} couldn't be read"
          : null;
      return switch (reason) {
        DeletionCheckSkipReason.incompleteFiles =>
          'Some $item files may be missing from this takeout, so $items '
              "missing from it weren't marked deleted. If the export was "
              'split into several zips, pick every part.',
        DeletionCheckSkipReason.savedDataUnverified =>
          'Your saved $items are newer than this takeout but may be '
              "incomplete, so $items weren't marked deleted. Add a newer, "
              'complete takeout to check them.',
        DeletionCheckSkipReason.unparsedRows =>
          '${unreadRows ?? "Some rows couldn't be read"}, so $items missing '
              "from this takeout weren't marked deleted.",
        null => unreadRows != null ? '$unreadRows.' : null,
      };
    }

    final data = plan.mergedData;
    return [
      ?warning(plan.commentCheckSkipped, data.skippedCommentRows, 'comment'),
      ?warning(
        plan.liveChatCheckSkipped,
        data.skippedLiveChatRows,
        'live chat',
      ),
    ];
  }
}

String _count(int n, String noun) => '$n ${n == 1 ? noun : '${noun}s'}';

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Line(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(text)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Notice({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
