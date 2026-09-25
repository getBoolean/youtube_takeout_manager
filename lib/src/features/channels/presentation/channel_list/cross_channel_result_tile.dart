import 'package:auto_route/auto_route.dart';
import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/channel_providers.dart';
import '../../domain/search_result_item.dart';

class CrossChannelResultTile extends ConsumerWidget {
  final SearchResultItem item;
  final String query;
  final ValueNotifier<bool> selectionMode;

  const CrossChannelResultTile({
    super.key,
    required this.item,
    required this.query,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final channel = ref.watch(channelByIdProvider(item.channelId));
    final isQueued = _isQueued(ref);
    final isFailed = _isFailed(ref);
    final ineligible = isQueued || isFailed;
    final isSelected = ref.watch(
      deletionSetProvider.select((s) => s.contains(item.id)),
    );
    final spans = buildCommentSpans(
      item.rawText,
      emojiSize: 16,
      emojiBuilder: EmojiPreview.highlighting(query),
    );

    final isComment = item.kind == QueueItemKind.comment;
    final channelName = channel?.channelTitle ?? item.channelId;
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
          channelId: item.channelId,
          targetKind: item.kind == QueueItemKind.comment
              ? 'comment'
              : 'liveChat',
          targetId: item.id,
        ),
      );
    }

    return AnimatedOpacity(
      opacity: (isQueued || isFailed) ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Cue.onChange(
            value: selectionMode.value,
            motion: premiumSpring(context),
            acts: const [OpacityAct.fadeIn()],
            child: Center(
              child: selectionMode.value
                  ? Checkbox(
                      key: const ValueKey('checkbox'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: isSelected,
                      onChanged: ineligible ? null : (_) => toggleSelection(),
                    )
                  : Icon(
                      key: const ValueKey('icon'),
                      isComment
                          ? Icons.comment_outlined
                          : Icons.chat_bubble_outline,
                      color: isComment
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
            ),
          ),
        ),
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
              TextSpan(
                text: '$channelName · ${formatDateTime(item.createdAt)}',
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: subtitleStyle,
        ),
        trailing: isQueued
            ? Icon(
                Icons.hourglass_top,
                size: 18,
                color: theme.colorScheme.tertiary,
              )
            : isFailed
            ? Icon(
                Icons.error_outline,
                size: 18,
                color: theme.colorScheme.error,
              )
            : const Icon(Icons.chevron_right),
        selected: isSelected,
        onTap: selectionMode.value
            ? (ineligible ? () {} : toggleSelection)
            : navigateToDetail,
        onLongPress: ineligible
            ? null
            : () {
                selectionMode.value = true;
                toggleSelection();
              },
      ),
    );
  }

  bool _isQueued(WidgetRef ref) {
    return item.kind == QueueItemKind.comment
        ? ref.watch(queuedCommentIdsProvider).contains(item.id)
        : ref.watch(queuedLiveChatIdsProvider).contains(item.id);
  }

  bool _isFailed(WidgetRef ref) {
    return item.kind == QueueItemKind.comment
        ? ref.watch(failedCommentIdsProvider).contains(item.id)
        : ref.watch(failedLiveChatIdsProvider).contains(item.id);
  }
}
