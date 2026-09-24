import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/deletion_method.dart';

/// Asks the user how to delete [itemCount] items. Returns `null` if they
/// cancel, including declining the YouTube API confirmation.
Future<DeletionMethod?> pickDeletionMethod(
  BuildContext context, {
  required String title,
  required int itemCount,
  int possibleMembershipEventCount = 0,
  bool offerAddToQueue = true,
  bool youtubeApiAvailable = true,
}) async {
  final method = await showModalBottomSheet<DeletionMethod>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (possibleMembershipEventCount > 0)
            _PossibleMembershipEventWarning(
              count: possibleMembershipEventCount,
            ),
          if (offerAddToQueue)
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Queue for Deletion'),
              subtitle: const Text('Choose how to delete them later'),
              onTap: () =>
                  Navigator.pop(sheetContext, DeletionMethod.addToQueue),
            ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Via My Activity'),
            subtitle: const Text('No daily limit — runs in your browser'),
            trailing: const _RecommendedBadge(),
            onTap: () =>
                Navigator.pop(sheetContext, DeletionMethod.myActivityScript),
          ),
          ListTile(
            enabled: youtubeApiAvailable,
            leading: const Icon(Icons.cloud_off),
            title: const Text('Via YouTube API'),
            subtitle: Text(
              youtubeApiAvailable
                  ? '~200 deletes/day quota limit'
                  : 'Sign in required',
            ),
            onTap: () => Navigator.pop(sheetContext, DeletionMethod.youtubeApi),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (method == DeletionMethod.youtubeApi && context.mounted) {
    final confirmed = await _confirmYoutubeApiDeletion(context, itemCount);
    return confirmed ? method : null;
  }
  return method;
}

Future<bool> _confirmYoutubeApiDeletion(BuildContext context, int count) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete via YouTube API'),
      content: Text(
        Intl.plural(
          count,
          one: 'Permanently delete 1 item from YouTube now?',
          other: 'Permanently delete $count items from YouTube now?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Recommended',
        style: TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PossibleMembershipEventWarning extends StatelessWidget {
  final int count;

  const _PossibleMembershipEventWarning({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = Intl.plural(
      count,
      one:
          '1 item may be a membership event or already-deleted message. '
          'Deletion may fail for it.',
      other:
          '$count items may be membership events or already-deleted '
          'messages. Deletion may fail for these.',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
