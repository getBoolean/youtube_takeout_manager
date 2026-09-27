import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/deletion_queue_notifier.dart';

/// Items queued before their channel was saved that the loaded takeout
/// doesn't have. They wait, undeleted, for the takeout they came from.
class UnassignedQueueNotice extends ConsumerWidget {
  final int count;

  const UnassignedQueueNotice({super.key, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Intl.plural(
                  count,
                  one:
                      "1 item queued before channels were tracked isn't in "
                      "this takeout. It'll show when you view the takeout it "
                      'came from.',
                  other:
                      "$count items queued before channels were tracked aren't "
                      "in this takeout. They'll show when you view the "
                      'takeout they came from.',
                ),
                style: theme.textTheme.bodySmall,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => ref
                      .read(deletionQueueProvider.notifier)
                      .removeUnassigned(),
                  child: Text(
                    count == 1 ? 'Remove it' : 'Remove them',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
