import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../utils/comment_text_parser.dart';
import '../utils/date_formatter.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isSelected;
  final bool isDeleted;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CommentTile({
    super.key,
    required this.comment,
    required this.isSelected,
    this.isDeleted = false,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isReply = comment.parentCommentId != null;
    final theme = Theme.of(context);

    return Opacity(
      opacity: isDeleted ? 0.5 : 1.0,
      child: ListTile(
        leading: selectionMode
            ? Checkbox(value: isSelected, onChanged: (_) => onTap())
            : Icon(
                isDeleted
                    ? Icons.delete_outline
                    : isReply
                        ? Icons.reply
                        : Icons.comment_outlined,
                color: isDeleted
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
        title: Text.rich(
          TextSpan(
            children: buildCommentSpans(
              comment.rawCommentText,
              emojiSize: 20,
            ),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: isDeleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          isDeleted
              ? 'Deleted • ${formatDateTime(comment.createdAt)}'
              : '${formatDateTime(comment.createdAt)}'
                  '${comment.videoId != null ? ' • Video: ${comment.videoId}' : ''}',
        ),
        selected: isSelected,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
