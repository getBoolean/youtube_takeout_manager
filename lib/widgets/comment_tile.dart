import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../utils/date_formatter.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CommentTile({
    super.key,
    required this.comment,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isReply = comment.parentCommentId != null;

    return ListTile(
      leading: selectionMode
          ? Checkbox(value: isSelected, onChanged: (_) => onTap())
          : Icon(
              isReply ? Icons.reply : Icons.comment_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
      title: Text(
        comment.displayText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${formatDateTime(comment.createdAt)}'
        '${comment.videoId != null ? ' • Video: ${comment.videoId}' : ''}',
      ),
      selected: isSelected,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
