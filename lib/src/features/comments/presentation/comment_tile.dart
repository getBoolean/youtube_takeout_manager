import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/presentation/superchat_card.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/comment.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isSelected;
  final bool isDeleted;
  final bool isQueued;
  final bool isFailed;
  final bool selectionMode;
  final String? highlightQuery;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CommentTile({
    super.key,
    required this.comment,
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
    final spans = buildCommentSpans(
      comment.rawCommentText,
      emojiSize: 20,
      emojiBuilder: EmojiPreview.highlighting(highlightQuery),
    );
    final subtitle = _subtitleFor(
      isDeleted: isDeleted,
      isFailed: isFailed,
      isQueued: isQueued,
      createdAt: comment.createdAt,
    );

    if (comment.price > 0) {
      return SuperChatCard(
        priceMicros: comment.price,
        currencyCode: 'USD',
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

    final isReply = comment.parentCommentId != null;
    final theme = Theme.of(context);

    final leadingIcon = _leadingIcon(
      isDeleted: isDeleted,
      isFailed: isFailed,
      isQueued: isQueued,
      fallback: isReply ? Icons.reply : Icons.comment_outlined,
    );
    final leadingColor = _leadingColor(
      theme,
      isDeleted: isDeleted,
      isFailed: isFailed,
      isQueued: isQueued,
    );

    return AnimatedOpacity(
      opacity: isDeleted ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Cue.onChange(
            value: selectionMode,
            motion: premiumSpring(context),
            acts: const [OpacityAct.fadeIn()],
            child: Center(
              child: selectionMode
                  ? Checkbox(
                      key: const ValueKey('checkbox'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: isSelected,
                      onChanged: (_) => onTap(),
                    )
                  : Cue.onChange(
                      key: const ValueKey('icon'),
                      value: leadingIcon.codePoint,
                      motion: premiumSpring(context),
                      acts: const [OpacityAct.fadeIn(), ScaleAct(from: 0.7)],
                      child: Icon(
                        leadingIcon,
                        key: ValueKey(leadingIcon.codePoint),
                        color: leadingColor,
                      ),
                    ),
            ),
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

String _subtitleFor({
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

IconData _leadingIcon({
  required bool isDeleted,
  required bool isFailed,
  required bool isQueued,
  required IconData fallback,
}) {
  if (isDeleted) return Icons.delete_outline;
  if (isFailed) return Icons.error_outline;
  if (isQueued) return Icons.schedule;
  return fallback;
}

Color _leadingColor(
  ThemeData theme, {
  required bool isDeleted,
  required bool isFailed,
  required bool isQueued,
}) {
  final scheme = theme.colorScheme;
  if (isDeleted || isFailed) return scheme.error;
  if (isQueued) return scheme.tertiary;
  return scheme.primary;
}
