import 'package:flutter/material.dart';

/// Shown while nothing is queued: how to add items.
class EmptyDeletionQueue extends StatelessWidget {
  const EmptyDeletionQueue({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.playlist_add_check,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Nothing queued', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Use Select or Queue… to add items.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
