import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/deletion_item_status.dart';
import '../domain/deletion_queue_item.dart';
import 'status_pill.dart';

class DeletionQueueItemTile extends StatelessWidget {
  final DeletionQueueItem item;
  final VoidCallback? onRemove;

  /// Below this width the status moves from a chip beside the text into the
  /// subtitle, so the trailing widget always fits.
  static const _statusChipMinWidth = 300.0;

  const DeletionQueueItemTile({super.key, required this.item, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildTile(
        context,
        statusChip: constraints.maxWidth >= _statusChipMinWidth,
      ),
    );
  }

  Widget _buildTile(BuildContext context, {required bool statusChip}) {
    final colorScheme = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = _status(item.status);
    final date = formatDateTime(item.createdAt);

    return ListTile(
      leading: Icon(
        item.itemType == QueueItemKind.comment
            ? Icons.comment_outlined
            : Icons.chat_bubble_outline,
        color: colorScheme.primary,
      ),
      title: Text(
        item.displayTextSnippet ?? item.itemId,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (statusChip)
            Text(date)
          else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: ' · $date'),
                ],
              ),
            ),
          if (item.errorMessage != null)
            Text(
              item.errorMessage!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusChip) StatusPill(label: statusLabel, color: statusColor),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              tooltip: 'Remove from queue',
            ),
        ],
      ),
    );
  }
}

(String, Color) _status(DeletionItemStatus status) => switch (status) {
  DeletionItemStatus.pending => ('Pending', Colors.grey),
  DeletionItemStatus.inProgress => ('Deleting...', Colors.blue),
  DeletionItemStatus.succeeded => ('Deleted', Colors.green),
  DeletionItemStatus.failed => ('Failed', Colors.red),
  DeletionItemStatus.quotaExceeded => ('Quota', Colors.orange),
};
