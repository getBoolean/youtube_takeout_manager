import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/comment_spans.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/interaction_tile.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/superchat_card.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/comment.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isSelected;
  final InteractionStatus status;
  final bool selectionMode;
  final String? highlightQuery;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CommentTile({
    super.key,
    required this.comment,
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
      comment.rawCommentText,
      emojiSize: 20,
      emojiBuilder: EmojiPreview.highlighting(highlightQuery),
    );
    final subtitle = status.labelled(formatDateTime(comment.createdAt));

    if (comment.price > 0) {
      return SuperChatCard(
        priceMicros: comment.price,
        currencyCode: 'USD',
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

    final isReply = comment.parentCommentId != null;
    return InteractionTile(
      status: status,
      icon: isReply ? Icons.reply : Icons.comment_outlined,
      iconColor: Theme.of(context).colorScheme.primary,
      title: HighlightedText.rich(
        spans,
        query: highlightQuery,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: status == InteractionStatus.deleted
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
