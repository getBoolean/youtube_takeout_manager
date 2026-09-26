import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/comments/presentation/comment_tile.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/presentation/live_chat_tile.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/grouped_providers.dart';
import 'channel_item_actions.dart';
import 'video_group_list_view.dart';

/// A channel's comments or live chats, grouped by video.
class ChannelInteractionListView extends ConsumerWidget {
  final QueueItemKind kind;
  final String channelId;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;
  final String? initialScrollTarget;

  const ChannelInteractionListView({
    super.key,
    required this.kind,
    required this.channelId,
    required this.selectionMode,
    required this.scrollController,
    this.initialScrollTarget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(channelContentSearchQueryProvider);
    final groups = ref.watch(
      filteredGroupedChannelInteractionsProvider(kind, channelId),
    );
    if (groups.isEmpty) {
      return EmptyState(
        icon: query.isNotEmpty
            ? Icons.search_off
            : switch (kind) {
                QueueItemKind.comment => Icons.comment_outlined,
                QueueItemKind.liveChat => Icons.chat_bubble_outline,
              },
        message: query.isNotEmpty
            ? 'No results'
            : switch (kind) {
                QueueItemKind.comment => 'No comments',
                QueueItemKind.liveChat => 'No live chats',
              },
      );
    }
    return VideoGroupListView(
      groups: groups,
      statuses: ref.watch(interactionStatusesProvider(kind)),
      selectionMode: selectionMode,
      scrollController: scrollController,
      initialScrollTarget: initialScrollTarget,
      tileBuilder: (context, item, status) => _InteractionTileConsumer(
        item: item,
        status: status,
        selectionMode: selectionMode,
        highlightQuery: query,
      ),
    );
  }
}

class _InteractionTileConsumer extends ConsumerWidget {
  final Interaction item;
  final InteractionStatus status;
  final ValueNotifier<bool> selectionMode;
  final String highlightQuery;

  const _InteractionTileConsumer({
    required this.item,
    required this.status,
    required this.selectionMode,
    required this.highlightQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      deletionSetProvider.select((s) => s.contains(item.id)),
    );
    final VoidCallback onTap = status == InteractionStatus.deleted
        ? () {}
        : selectionMode.value
        ? (status.isSelectable
              ? () => ref.read(deletionSetProvider.notifier).toggle(item.id)
              : () {})
        : () => showSingleItemActions(context, ref, item: item, status: status);
    final VoidCallback onLongPress = status.isSelectable
        ? () {
            selectionMode.value = true;
            ref.read(deletionSetProvider.notifier).toggle(item.id);
          }
        : () {};

    return switch (item) {
      final Comment comment => CommentTile(
        comment: comment,
        isSelected: isSelected,
        status: status,
        selectionMode: selectionMode.value,
        highlightQuery: highlightQuery,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
      final LiveChat liveChat => LiveChatTile(
        liveChat: liveChat,
        isSelected: isSelected,
        status: status,
        selectionMode: selectionMode.value,
        highlightQuery: highlightQuery,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
      _ => throw ArgumentError.value(
        item,
        'item',
        'Not a comment or live chat',
      ),
    };
  }
}
