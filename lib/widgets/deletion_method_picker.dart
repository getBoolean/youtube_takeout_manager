import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/script_deletion_provider.dart';
import '../router/app_router.dart';

/// Shows a bottom sheet letting the user choose between My Activity
/// script-based deletion (no quota) or YouTube API deletion (quota limited).
///
/// [ids] contains all selected comment and/or live chat IDs.
/// [onApiChosen] is called if the user picks the API fallback.
void showDeletionMethodPicker(
  BuildContext context, {
  required WidgetRef ref,
  required Set<String> ids,
  int uncertainLiveChatCount = 0,
  VoidCallback? onApiChosen,
}) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              Intl.plural(
                ids.length,
                one: 'Delete 1 item',
                other: 'Delete ${ids.length} items',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (uncertainLiveChatCount > 0)
            _UncertainDeletionWarning(count: uncertainLiveChatCount),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Via My Activity'),
            subtitle: const Text('No daily limit — runs in your browser'),
            trailing: Container(
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
            ),
            onTap: () {
              Navigator.pop(ctx);
              ref.read(scriptDeletionIdsProvider.notifier).set(ids);
              context.router.push(const ScriptDeletionRoute());
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_off),
            title: const Text('Via YouTube API'),
            subtitle: const Text('~200 deletes/day quota limit'),
            onTap: () {
              Navigator.pop(ctx);
              _confirmApiDeletion(context, ids.length, onApiChosen);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _UncertainDeletionWarning extends StatelessWidget {
  final int count;

  const _UncertainDeletionWarning({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = Intl.plural(
      count,
      one: '1 item may be a membership event or already-deleted message. '
          'Deletion may fail for it.',
      other: '$count items may be membership events or already-deleted '
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

void _confirmApiDeletion(
  BuildContext context,
  int count,
  VoidCallback? onConfirmed,
) {
  final message = Intl.plural(
    count,
    one: 'Queue 1 item for permanent deletion from YouTube?',
    other: 'Queue $count items for permanent deletion from YouTube?',
  );
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete via YouTube API'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirmed?.call();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
