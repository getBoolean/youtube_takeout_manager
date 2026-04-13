import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              'Delete ${ids.length} item(s)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
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
                    fontWeight: FontWeight.w500),
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

void _confirmApiDeletion(
  BuildContext context,
  int count,
  VoidCallback? onConfirmed,
) {
  final label = count == 1 ? 'item' : 'items';
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete via YouTube API'),
      content: Text(
          'Queue $count $label for permanent deletion from YouTube?'),
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
