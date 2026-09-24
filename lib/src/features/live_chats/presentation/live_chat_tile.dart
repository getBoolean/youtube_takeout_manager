import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../model/live_chat.dart';
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
    final spans = buildCommentSpans(
      liveChat.rawText,
      emojiSize: 20,
      emojiBuilder: EmojiPreview.builder,
    );
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
    final isEmptyText = liveChat.rawText.trim().isEmpty;

    final leadingIcon = _liveChatLeadingIcon(
      isDeleted: isDeleted,
      isFailed: isFailed,
      isQueued: isQueued,
    );
    final leadingColor = _liveChatLeadingColor(
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
        title: isEmptyText
            ? Text(
                'Likely a membership event or deleted message',
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
