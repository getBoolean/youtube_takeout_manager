import 'package:flutter/material.dart';

import '../models/live_chat.dart';
import '../utils/comment_text_parser.dart';
import '../utils/date_formatter.dart';
import 'highlighted_text.dart';
import 'superchat_card.dart';

class LiveChatTile extends StatelessWidget {
  final LiveChat liveChat;
  final bool isSelected;
  final bool isDeleted;
  final bool isQueued;
  final bool isFailed;
  final bool selectionMode;
  final String? highlightQuery;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LiveChatTile({
    super.key,
    required this.liveChat,
    required this.isSelected,
    this.isDeleted = false,
    this.isQueued = false,
    this.isFailed = false,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final spans = buildCommentSpans(liveChat.rawText, emojiSize: 20);
    final subtitle = _liveChatSubtitle(
      isDeleted: isDeleted,
      isFailed: isFailed,
      isQueued: isQueued,
      createdAt: liveChat.createdAt,
    );

    if (liveChat.price > 0) {
      return SuperChatCard(
        priceMicros: liveChat.price,
        currencyCode: liveChat.currencyCode ?? 'USD',
        messageSpans: spans,
        highlightQuery: highlightQuery,
        subtitleText: subtitle,
        isSelected: isSelected,
        isDeleted: isDeleted,
        isQueued: isQueued,
        isFailed: isFailed,
        selectionMode: selectionMode,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

    final theme = Theme.of(context);

    return Opacity(
      opacity: isDeleted ? 0.5 : 1.0,
      child: ListTile(
        leading: selectionMode
            ? Checkbox(value: isSelected, onChanged: (_) => onTap())
            : Icon(
                _liveChatLeadingIcon(
                  isDeleted: isDeleted,
                  isFailed: isFailed,
                  isQueued: isQueued,
                ),
                color: _liveChatLeadingColor(
                  theme,
                  isDeleted: isDeleted,
                  isFailed: isFailed,
                  isQueued: isQueued,
                ),
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
        subtitle: Text(subtitle),
        selected: isSelected,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

String _liveChatSubtitle({
  required bool isDeleted,
  required bool isFailed,
  required bool isQueued,
  required DateTime createdAt,
}) {
  final date = formatDateTime(createdAt);
  if (isDeleted) return 'Deleted • $date';
  if (isFailed) return 'Failed • $date';
  if (isQueued) return 'Queued • $date';
  return date;
}

IconData _liveChatLeadingIcon({
  required bool isDeleted,
  required bool isFailed,
  required bool isQueued,
}) {
  if (isDeleted) return Icons.delete_outline;
  if (isFailed) return Icons.error_outline;
  if (isQueued) return Icons.schedule;
  return Icons.chat_bubble_outline;
}

Color _liveChatLeadingColor(
  ThemeData theme, {
  required bool isDeleted,
  required bool isFailed,
  required bool isQueued,
}) {
  final scheme = theme.colorScheme;
  if (isDeleted || isFailed) return scheme.error;
  if (isQueued) return scheme.tertiary;
  return scheme.secondary;
}
