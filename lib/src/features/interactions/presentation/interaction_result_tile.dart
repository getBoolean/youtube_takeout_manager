import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_meta_line.dart';
import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/presentation/live_chat_tile.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/interaction.dart';
import '../domain/interaction_status.dart';
import '../domain/queue_item_kind.dart';
import 'comment_spans.dart';
import 'interaction_tile.dart';
import 'superchat_colors.dart';

/// A comment or live chat listed away from its channel's page, as search
/// results are: its text, then the channel it's on and when.
class InteractionResultTile extends StatelessWidget {
  final Interaction item;
  final String channelName;
  final String? channelThumbnailUrl;
  final InteractionStatus status;

  /// Highlighted in the text; empty for none.
  final String query;
  final bool isSelected;
  final bool selectionMode;

  /// Shown at the end of the row; a chevron when null.
  final Widget? trailing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const InteractionResultTile({
    super.key,
    required this.item,
    required this.channelName,
    this.channelThumbnailUrl,
    required this.status,
    this.query = '',
    this.isSelected = false,
    this.selectionMode = false,
    this.trailing,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spans = buildCommentSpans(
      item.rawText,
      emojiSize: 16,
      emojiBuilder: EmojiPreview.highlighting(query),
    );
    final isComment = item.kind == QueueItemKind.comment;

    return InteractionTile(
      status: status,
      icon: isComment ? Icons.comment_outlined : Icons.chat_bubble_outline,
      iconColor: isComment
          ? theme.colorScheme.primary
          : theme.colorScheme.secondary,
      dimUnselectable: true,
      title: item.rawText.trim().isEmpty
          ? Text(
              _emptyTextLabel(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : HighlightedText.rich(
              spans,
              query: query,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
      subtitle: ChannelMetaLine(
        prefix: 'on ',
        channelName: channelName,
        thumbnailUrl: channelThumbnailUrl,
        detail: formatDateTime(item.createdAt),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      isSelected: isSelected,
      selectionMode: selectionMode,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  /// What stands in for [item]'s text when it has none: a Super Chat's
  /// amount, or what a live chat likely was.
  String _emptyTextLabel() {
    final (:price, :currencyCode) = item.when(
      comment: (c) => (price: c.price, currencyCode: 'USD'),
      liveChat: (l) => (price: l.price, currencyCode: l.currencyCode ?? 'USD'),
    );
    if (price > 0) {
      return '${formatSuperChatPrice(price, currencyCode)} Super Chat with no '
          'message';
    }
    return item.kind == QueueItemKind.liveChat ? emptyLiveChatLabel : 'No text';
  }
}
