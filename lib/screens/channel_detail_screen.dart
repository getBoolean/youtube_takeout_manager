import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/comment_providers.dart';
import '../providers/deletion_providers.dart';
import '../providers/live_chat_providers.dart';
import '../providers/takeout_providers.dart';
import '../widgets/comment_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/live_chat_tile.dart';

@RoutePage()
class ChannelDetailScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelDetailScreen({
    super.key,
    @PathParam('channelId') required this.channelId,
  });

  @override
  ConsumerState<ChannelDetailScreen> createState() =>
      _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen> {
  bool _selectionMode = false;

  void _toggleSelection(String id) {
    ref.read(deletionSetProvider.notifier).toggle(id);
  }

  void _enterSelectionMode(String id) {
    setState(() => _selectionMode = true);
    ref.read(deletionSetProvider.notifier).toggle(id);
  }

  void _exitSelectionMode() {
    setState(() => _selectionMode = false);
    ref.read(deletionSetProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(channelCommentsProvider(widget.channelId));
    final liveChats = ref.watch(channelLiveChatsProvider(widget.channelId));
    final selectedIds = ref.watch(deletionSetProvider);
    final takeout = ref.watch(takeoutProvider);
    final sub = takeout?.subscriptionsByChannelId[widget.channelId];
    final channelName = sub?.channelTitle ?? 'Unknown Channel';

    final hasComments = comments.isNotEmpty;
    final hasLiveChats = liveChats.isNotEmpty;
    final useTabs = hasComments && hasLiveChats;

    return useTabs
        ? _buildTabbedView(
            context, channelName, comments, liveChats, selectedIds)
        : _buildSingleView(
            context, channelName, comments, liveChats, selectedIds);
  }

  Widget _buildTabbedView(
    BuildContext context,
    String channelName,
    List comments,
    List liveChats,
    Set<String> selectedIds,
  ) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(channelName),
          leading: _selectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                )
              : null,
          actions: _buildActions(comments, liveChats),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Comments (${comments.length})'),
              Tab(text: 'Live Chats (${liveChats.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCommentList(comments, selectedIds),
            _buildLiveChatList(liveChats, selectedIds),
          ],
        ),
        bottomNavigationBar:
            _selectionMode && selectedIds.isNotEmpty
                ? _buildDeletionBar(context, selectedIds)
                : null,
      ),
    );
  }

  Widget _buildSingleView(
    BuildContext context,
    String channelName,
    List comments,
    List liveChats,
    Set<String> selectedIds,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(channelName),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _buildActions(comments, liveChats),
      ),
      body: comments.isNotEmpty
          ? _buildCommentList(comments, selectedIds)
          : liveChats.isNotEmpty
              ? _buildLiveChatList(liveChats, selectedIds)
              : const EmptyState(
                  icon: Icons.inbox_outlined,
                  message: 'No interactions found',
                ),
      bottomNavigationBar:
          _selectionMode && selectedIds.isNotEmpty
              ? _buildDeletionBar(context, selectedIds)
              : null,
    );
  }

  List<Widget> _buildActions(List comments, List liveChats) {
    if (!_selectionMode) return [];
    return [
      PopupMenuButton<String>(
        onSelected: (value) {
          final notifier = ref.read(deletionSetProvider.notifier);
          if (value == 'select_all_comments') {
            notifier.addAll(comments.map((c) => c.commentId as String));
          } else if (value == 'select_all_chats') {
            notifier.addAll(liveChats.map((c) => c.liveChatId as String));
          }
        },
        itemBuilder: (context) => [
          if (comments.isNotEmpty)
            const PopupMenuItem(
              value: 'select_all_comments',
              child: Text('Select All Comments'),
            ),
          if (liveChats.isNotEmpty)
            const PopupMenuItem(
              value: 'select_all_chats',
              child: Text('Select All Live Chats'),
            ),
        ],
      ),
    ];
  }

  Widget _buildCommentList(List comments, Set<String> selectedIds) {
    if (comments.isEmpty) {
      return const EmptyState(
          icon: Icons.comment_outlined, message: 'No comments');
    }
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return CommentTile(
          comment: comment,
          isSelected: selectedIds.contains(comment.commentId),
          selectionMode: _selectionMode,
          onTap: _selectionMode
              ? () => _toggleSelection(comment.commentId)
              : () {},
          onLongPress: () => _enterSelectionMode(comment.commentId),
        );
      },
    );
  }

  Widget _buildLiveChatList(List liveChats, Set<String> selectedIds) {
    if (liveChats.isEmpty) {
      return const EmptyState(
          icon: Icons.chat_bubble_outline, message: 'No live chats');
    }
    return ListView.builder(
      itemCount: liveChats.length,
      itemBuilder: (context, index) {
        final chat = liveChats[index];
        return LiveChatTile(
          liveChat: chat,
          isSelected: selectedIds.contains(chat.liveChatId),
          selectionMode: _selectionMode,
          onTap: _selectionMode
              ? () => _toggleSelection(chat.liveChatId)
              : () {},
          onLongPress: () => _enterSelectionMode(chat.liveChatId),
        );
      },
    );
  }

  Widget _buildDeletionBar(BuildContext context, Set<String> selectedIds) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Items'),
                content: Text(
                    'Remove ${selectedIds.length} selected item(s) from the list?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final notifier =
                          ref.read(deletionSetProvider.notifier);
                      notifier.removeSelectedComments();
                      notifier.removeSelectedLiveChats();
                      Navigator.pop(ctx);
                      _exitSelectionMode();
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.delete_outline),
          label: Text('Delete ${selectedIds.length} item(s)'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      ),
    );
  }
}
