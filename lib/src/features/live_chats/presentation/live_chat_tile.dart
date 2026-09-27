import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/comment_spans.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/interaction_tile.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/superchat_card.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/live_chat.dart';

/// Stands in for a live chat with no text, which can be a membership event.
const emptyLiveChatLabel = 'Likely a membership event or deleted message';

class LiveChatTile extends StatelessWidget {
  final LiveChat liveChat;
  final bool isSelected;
  final InteractionStatus status;
  final bool selectionMode;
  final String? highlightQuery;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const LiveChatTile({
    super.key,
    required this.liveChat,
    required this.isSelected,
    this.status = InteractionStatus.active,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final spans = buildCommentSpans(
      liveChat.rawText,
      emojiSize: 20,
      emojiBuilder: EmojiPreview.highlighting(highlightQuery),
    );
    final subtitle = status.labelled(formatDateTime(liveChat.createdAt));

    if (liveChat.price > 0) {
      return SuperChatCard(
        priceMicros: liveChat.price,
        currencyCode: liveChat.currencyCode ?? 'USD',
        messageSpans: spans,
        highlightQuery: highlightQuery,
        subtitleText: subtitle,
        isSelected: isSelected,
        status: status,
        selectionMode: selectionMode,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }

    final theme = Theme.of(context);
    final isDeleted = status == InteractionStatus.deleted;
    return InteractionTile(
      status: status,
      icon: Icons.chat_bubble_outline,
      iconColor: theme.colorScheme.secondary,
      title: liveChat.rawText.trim().isEmpty
          ? Text(
              emptyLiveChatLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
                decoration: isDeleted ? TextDecoration.lineThrough : null,
              ),
            )
          : HighlightedText.rich(
              spans,
              query: highlightQuery,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: isDeleted
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
      subtitle: Text(subtitle),
      isSelected: isSelected,
      selectionMode: selectionMode,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
