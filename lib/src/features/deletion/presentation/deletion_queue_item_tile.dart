import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/deletion_item_status.dart';
import '../domain/deletion_queue_item.dart';
import '../domain/queue_item_kind.dart';

class DeletionQueueItemTile extends StatelessWidget {
  final DeletionQueueItem item;
  final VoidCallback? onRemove;

  const DeletionQueueItemTile({super.key, required this.item, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          Text(formatDateTime(item.createdAt)),
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
          _StatusChip(status: item.status),
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

class _StatusChip extends StatelessWidget {
  final DeletionItemStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DeletionItemStatus.pending => ('Pending', Colors.grey),
      DeletionItemStatus.inProgress => ('Deleting...', Colors.blue),
      DeletionItemStatus.succeeded => ('Deleted', Colors.green),
      DeletionItemStatus.failed => ('Failed', Colors.red),
      DeletionItemStatus.quotaExceeded => ('Quota', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
