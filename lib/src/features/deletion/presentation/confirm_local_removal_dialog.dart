import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Asks to confirm removing [count] items from the list only, without
/// deleting them from YouTube. Pops true to remove them.
class ConfirmLocalRemovalDialog extends StatelessWidget {
  final int count;

  const ConfirmLocalRemovalDialog({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remove Items'),
      content: Text(
        '${Intl.plural(count, one: 'Remove 1 item', other: 'Remove $count items')} from the list?\n\n'
        'Use this for items you already deleted manually outside the app. '
        'This does not delete them from YouTube.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}
