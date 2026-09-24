import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/presentation/live_chat_tile.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/grouped_providers.dart';
import 'channel_item_actions.dart';
import 'video_group_list_view.dart';

class ChannelLiveChatListView extends ConsumerWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;
  final String? initialScrollTarget;

  const ChannelLiveChatListView({
    super.key,
    required this.channelId,
    required this.selectionMode,
    required this.scrollController,
    this.initialScrollTarget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(channelContentSearchQueryProvider);
    final groups = ref.watch(
      filteredGroupedChannelLiveChatsProvider(channelId),
    );
    if (groups.isEmpty) {
      return EmptyState(
        icon: query.isEmpty ? Icons.chat_bubble_outline : Icons.search_off,
        message: query.isEmpty ? 'No live chats' : 'No results',
      );
    }
    return VideoGroupListView<LiveChat>(
      groups: groups,
      itemId: (chat) => chat.liveChatId,
      deletedIds: ref.watch(deletedLiveChatIdsProvider).value ?? const {},
      queuedIds: ref.watch(queuedLiveChatIdsProvider),
      failedIds: ref.watch(failedLiveChatIdsProvider),
      selectionMode: selectionMode,
      scrollController: scrollController,
      initialScrollTarget: initialScrollTarget,
      tileBuilder:
          (
            context,
            chat, {
            required isDeleted,
            required isQueued,
            required isFailed,
          }) => _LiveChatTileConsumer(
            chat: chat,
            isDeleted: isDeleted,
            isQueued: isQueued,
            isFailed: isFailed,
            selectionMode: selectionMode,
            highlightQuery: query,
          ),
    );
  }
}

class _LiveChatTileConsumer extends ConsumerWidget {
  final LiveChat chat;
  final bool isDeleted;
  final bool isQueued;
  final bool isFailed;
  final ValueNotifier<bool> selectionMode;
  final String highlightQuery;

  const _LiveChatTileConsumer({
    required this.chat,
    required this.isDeleted,
    required this.isQueued,
    required this.isFailed,
    required this.selectionMode,
    required this.highlightQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      deletionSetProvider.select((s) => s.contains(chat.liveChatId)),
    );
    final ineligible = isDeleted || isQueued || isFailed;
    return LiveChatTile(
      liveChat: chat,
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
                      .toggle(chat.liveChatId))
          : () => showSingleItemActions(
              context,
              ref,
              itemId: chat.liveChatId,
              displayText: chat.displayText,
              kind: QueueItemKind.liveChat,
              videoId: chat.videoId,
              isQueued: isQueued,
              isFailed: isFailed,
            ),
      onLongPress: ineligible
          ? () {}
          : () {
              selectionMode.value = true;
              ref.read(deletionSetProvider.notifier).toggle(chat.liveChatId);
            },
    );
  }
}
