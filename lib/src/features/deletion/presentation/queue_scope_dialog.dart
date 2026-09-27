import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/option_card.dart';
import '../domain/deletion_targets.dart';
import 'deletion_actions.dart';

/// One set of items the queue dialog offers, e.g. "All comments in X".
class QueueScope {
  final IconData icon;
  final String title;
  final DeletionTargets targets;

  /// Names what [targets] holds, e.g. `comments`, for the count line.
  final String Function(int count) describeCount;

  const QueueScope({
    required this.icon,
    required this.title,
    required this.targets,
    this.describeCount = describeItems,
  });

  static String describeItems(int count) =>
      Intl.plural(count, one: '1 item', other: '$count items');

  static String describeComments(int count) =>
      Intl.plural(count, one: '1 comment', other: '$count comments');

  static String describeLiveChats(int count) =>
      Intl.plural(count, one: '1 live chat', other: '$count live chats');
}

/// Asks which of [scopes] to add to the deletion queue, then queues it.
Future<void> queueWithScopeDialog(
  BuildContext context,
  WidgetRef ref,
  List<QueueScope> scopes,
) async {
  final targets = await showDialog<DeletionTargets>(
    context: context,
    builder: (_) => QueueScopeDialog(scopes: scopes),
  );
  if (targets == null || !context.mounted) return;
  await queueForDeletion(context, ref, targets);
}

class QueueScopeDialog extends StatefulWidget {
  final List<QueueScope> scopes;

  const QueueScopeDialog({super.key, required this.scopes});

  @override
  State<QueueScopeDialog> createState() => _QueueScopeDialogState();
}

class _QueueScopeDialogState extends State<QueueScopeDialog> {
  late int? _selected = _firstEnabled();

  int? _firstEnabled() {
    final index = widget.scopes.indexWhere((s) => !s.targets.isEmpty);
    return index == -1 ? null : index;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;
    final count = selected == null ? 0 : widget.scopes[selected].targets.count;

    return AlertDialog(
      // Title and buttons scroll too, and the margins shrink, so nothing
      // overflows in a tiny window.
      scrollable: true,
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      title: const Text('Add to deletion queue'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Items wait in the deletion queue until you delete them. '
              'Ones already deleted, queued or failed are left out.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final (i, scope) in widget.scopes.indexed) ...[
              OptionCard(
                icon: scope.icon,
                title: scope.title,
                subtitle: scope.describeCount(scope.targets.count),
                selected: i == selected,
                onTap: scope.targets.isEmpty
                    ? null
                    : () => setState(() => _selected = i),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: selected == null
              ? null
              : () => Navigator.pop(context, widget.scopes[selected].targets),
          // Left out in the narrowest windows so the button still fits.
          icon: isTinyWidth(context) ? null : const Icon(Icons.playlist_add),
          label: Text('Queue $count', overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
