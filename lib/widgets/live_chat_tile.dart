import 'package:flutter/material.dart';

import '../models/live_chat.dart';
import '../utils/comment_text_parser.dart';
import '../utils/date_formatter.dart';

class LiveChatTile extends StatelessWidget {
  final LiveChat liveChat;
  final bool isSelected;
  final bool isDeleted;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LiveChatTile({
    super.key,
    required this.liveChat,
    required this.isSelected,
    this.isDeleted = false,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: isDeleted ? 0.5 : 1.0,
      child: ListTile(
        leading: selectionMode
            ? Checkbox(value: isSelected, onChanged: (_) => onTap())
            : Icon(
                isDeleted ? Icons.delete_outline : Icons.chat_bubble_outline,
                color: isDeleted
                    ? theme.colorScheme.error
                    : theme.colorScheme.secondary,
              ),
        title: Text.rich(
          TextSpan(
            children: buildCommentSpans(
              liveChat.rawText,
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
              ? 'Deleted • ${formatDateTime(liveChat.createdAt)}'
              : '${formatDateTime(liveChat.createdAt)}'
                  '${liveChat.videoId != null ? ' • Stream: ${liveChat.videoId}' : ''}',
        ),
        selected: isSelected,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
