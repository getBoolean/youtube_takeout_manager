import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/interaction_tile.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/channel_providers.dart';
import '../../application/selection_providers.dart';
import '../../domain/search_result_item.dart';

class CrossChannelResultTile extends ConsumerWidget {
  final SearchResultItem result;
  final String query;

  const CrossChannelResultTile({
    super.key,
    required this.result,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = result.item;
    final theme = Theme.of(context);
    final channel = ref.watch(channelByIdProvider(result.channelId));
    final status = ref
        .watch(interactionStatusesProvider(item.kind))
        .of(item.id);
    final isSelected = ref.watch(
      deletionSetProvider.select((s) => s.contains(item.id)),
    );
    final selectionMode = selectionModeProvider();
    final selecting = ref.watch(selectionMode);
    final spans = buildCommentSpans(
      item.rawText,
      emojiSize: 16,
      emojiBuilder: EmojiPreview.highlighting(query),
    );

    final isComment = item.kind == QueueItemKind.comment;
    final channelName = channel?.channelTitle ?? result.channelId;
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    void toggleSelection() {
      ref.read(deletionSetProvider.notifier).toggle(item.id);
    }

    void navigateToDetail() {
      // Clear any stale channel search query so the target item
      // isn't filtered out on the detail screen.
      ref.read(channelContentSearchQueryProvider.notifier).update('');
      context.router.push(
        ChannelDetailRoute(
          channelId: result.channelId,
          targetKind: item.kind.name,
          targetId: item.id,
        ),
      );
    }

    return InteractionTile(
      status: status,
      icon: isComment ? Icons.comment_outlined : Icons.chat_bubble_outline,
      iconColor: isComment
          ? theme.colorScheme.primary
          : theme.colorScheme.secondary,
      dimUnselectable: true,
      title: HighlightedText.rich(
        spans,
        query: query,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      // One line of text with the avatar inline, so it ellipsizes instead
      // of overflowing when narrow.
      subtitle: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'on '),
            if (channel?.thumbnailUrl != null)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ClipOval(
                    child: Image.network(
                      channel!.thumbnailUrl!,
                      width: 14,
                      height: 14,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    ),
                  ),
                ),
              ),
            TextSpan(text: '$channelName · ${formatDateTime(item.createdAt)}'),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: subtitleStyle,
      ),
      trailing: const Icon(Icons.chevron_right),
      isSelected: isSelected,
      selectionMode: selecting,
      onTap: selecting
          ? (status.isSelectable ? toggleSelection : () {})
          : navigateToDetail,
      onLongPress: status.isSelectable
          ? () {
              ref.read(selectionMode.notifier).enter();
              toggleSelection();
            }
          : null,
    );
  }
}
