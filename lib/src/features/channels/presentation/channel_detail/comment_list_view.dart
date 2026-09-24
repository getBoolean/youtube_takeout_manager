import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/comments/presentation/comment_tile.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/grouped_providers.dart';
import 'channel_item_actions.dart';
import 'video_group_list_view.dart';

class ChannelCommentListView extends ConsumerWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;
  final String? initialScrollTarget;

  const ChannelCommentListView({
    super.key,
    required this.channelId,
    required this.selectionMode,
    required this.scrollController,
    this.initialScrollTarget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(channelContentSearchQueryProvider);
    final groups = ref.watch(filteredGroupedChannelCommentsProvider(channelId));
    if (groups.isEmpty) {
      return EmptyState(
        icon: query.isEmpty ? Icons.comment_outlined : Icons.search_off,
        message: query.isEmpty ? 'No comments' : 'No results',
      );
    }
    return VideoGroupListView<Comment>(
      groups: groups,
      itemId: (comment) => comment.commentId,
      deletedIds: ref.watch(deletedCommentIdsProvider).value ?? const {},
      queuedIds: ref.watch(queuedCommentIdsProvider),
      failedIds: ref.watch(failedCommentIdsProvider),
      selectionMode: selectionMode,
      scrollController: scrollController,
      initialScrollTarget: initialScrollTarget,
      tileBuilder:
          (
            context,
            comment, {
            required isDeleted,
            required isQueued,
            required isFailed,
          }) => _CommentTileConsumer(
            comment: comment,
            isDeleted: isDeleted,
            isQueued: isQueued,
            isFailed: isFailed,
            selectionMode: selectionMode,
            highlightQuery: query,
          ),
    );
  }
}

class _CommentTileConsumer extends ConsumerWidget {
  final Comment comment;
  final bool isDeleted;
  final bool isQueued;
  final bool isFailed;
  final ValueNotifier<bool> selectionMode;
  final String highlightQuery;

  const _CommentTileConsumer({
    required this.comment,
    required this.isDeleted,
    required this.isQueued,
    required this.isFailed,
    required this.selectionMode,
    required this.highlightQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      deletionSetProvider.select((s) => s.contains(comment.commentId)),
    );
    final ineligible = isDeleted || isQueued || isFailed;
    return CommentTile(
      comment: comment,
      isSelected: isSelected,
      isDeleted: isDeleted,
      isQueued: isQueued,
      isFailed: isFailed,
      selectionMode: selectionMode.value,
      highlightQuery: highlightQuery,
      onTap: isDeleted
          ? () {}
          : selectionMode.value
          ? (ineligible
                ? () {}
                : () => ref
                      .read(deletionSetProvider.notifier)
                      .toggle(comment.commentId))
          : () => showSingleItemActions(
              context,
              ref,
              itemId: comment.commentId,
              displayText: comment.displayText,
              kind: QueueItemKind.comment,
              videoId: comment.videoId,
              commentId: comment.commentId,
              isQueued: isQueued,
              isFailed: isFailed,
            ),
      onLongPress: ineligible
          ? () {}
          : () {
              selectionMode.value = true;
              ref.read(deletionSetProvider.notifier).toggle(comment.commentId);
            },
    );
  }
}
