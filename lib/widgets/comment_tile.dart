import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../utils/comment_text_parser.dart';
import '../utils/date_formatter.dart';
import 'highlighted_text.dart';
import 'superchat_card.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isSelected;
  final bool isDeleted;
  final bool selectionMode;
  final String? highlightQuery;
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
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final spans = buildCommentSpans(comment.rawCommentText, emojiSize: 20);

    if (comment.price > 0) {
      final subtitle = isDeleted
          ? 'Deleted • ${formatDateTime(comment.createdAt)}'
          : formatDateTime(comment.createdAt);

      return SuperChatCard(
        priceMicros: comment.price,
        currencyCode: 'USD',
        messageSpans: spans,
        highlightQuery: highlightQuery,
        subtitleText: subtitle,
        isSelected: isSelected,
        isDeleted: isDeleted,
        selectionMode: selectionMode,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

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
        title: HighlightedText.rich(
          spans,
          query: highlightQuery,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: isDeleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          isDeleted
              ? 'Deleted • ${formatDateTime(comment.createdAt)}'
              : formatDateTime(comment.createdAt),
        ),
        selected: isSelected,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
