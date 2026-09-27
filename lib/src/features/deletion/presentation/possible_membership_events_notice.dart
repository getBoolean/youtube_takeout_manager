import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';

/// Warns that [count] items are live chats with no text, which may be
/// membership events or already-deleted messages that won't delete.
///
/// Not a `NoticeBanner`: that lays out its title with a `LayoutBuilder`,
/// which an `AlertDialog`'s intrinsic sizing can't measure.
class PossibleMembershipEventsNotice extends StatelessWidget {
  final int count;

  const PossibleMembershipEventsNotice({super.key, required this.count});

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left out in the narrowest windows so the text still fits.
          if (!isTinyWidth(context)) ...[
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
          ],
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
    );
  }
}
