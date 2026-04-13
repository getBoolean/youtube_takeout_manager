import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/comment.dart';
import '../models/export_format.dart';
import '../models/live_chat.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/deleted_ids_providers.dart';
import '../providers/deletion_providers.dart';
import '../providers/deletion_queue_provider.dart';
import '../providers/export_providers.dart';
import '../providers/live_chat_providers.dart';
import '../providers/takeout_providers.dart';
import '../router/app_router.dart';
import '../widgets/comment_tile.dart';
import '../widgets/deletion_method_picker.dart';
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
    final deletedCommentIds =
        ref.watch(deletedCommentIdsProvider).value ?? {};
    final deletedLiveChatIds =
        ref.watch(deletedLiveChatIdsProvider).value ?? {};
    final takeout = ref.watch(takeoutProvider).value;
    final sub = takeout?.subscriptionsByChannelId[widget.channelId];
    final channelName = sub?.channelTitle ?? 'Unknown Channel';

    final hasComments = comments.isNotEmpty;
    final hasLiveChats = liveChats.isNotEmpty;
    final useTabs = hasComments && hasLiveChats;

    return useTabs
        ? _buildTabbedView(context, channelName, comments, liveChats,
            selectedIds, deletedCommentIds, deletedLiveChatIds)
        : _buildSingleView(context, channelName, comments, liveChats,
            selectedIds, deletedCommentIds, deletedLiveChatIds);
  }

  Widget _buildTabbedView(
    BuildContext context,
    String channelName,
    List<Comment> comments,
    List<LiveChat> liveChats,
    Set<String> selectedIds,
    Set<String> deletedCommentIds,
    Set<String> deletedLiveChatIds,
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
          actions: _buildActions(comments, liveChats, deletedCommentIds, deletedLiveChatIds),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Comments (${comments.length})'),
              Tab(text: 'Live Chats (${liveChats.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCommentList(comments, selectedIds, deletedCommentIds),
            _buildLiveChatList(liveChats, selectedIds, deletedLiveChatIds),
          ],
        ),
        bottomNavigationBar:
            _selectionMode && selectedIds.isNotEmpty
                ? _buildDeletionBar(context, selectedIds, comments, liveChats)
                : null,
      ),
    );
  }

  Widget _buildSingleView(
    BuildContext context,
    String channelName,
    List<Comment> comments,
    List<LiveChat> liveChats,
    Set<String> selectedIds,
    Set<String> deletedCommentIds,
    Set<String> deletedLiveChatIds,
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
        actions: _buildActions(comments, liveChats, deletedCommentIds, deletedLiveChatIds),
      ),
      body: comments.isNotEmpty
          ? _buildCommentList(comments, selectedIds, deletedCommentIds)
          : liveChats.isNotEmpty
              ? _buildLiveChatList(liveChats, selectedIds, deletedLiveChatIds)
              : const EmptyState(
                  icon: Icons.inbox_outlined,
                  message: 'No interactions found',
                ),
      bottomNavigationBar:
          _selectionMode && selectedIds.isNotEmpty
              ? _buildDeletionBar(context, selectedIds, comments, liveChats)
              : null,
    );
  }

  List<Widget> _buildActions(
    List<Comment> comments,
    List<LiveChat> liveChats,
    Set<String> deletedCommentIds,
    Set<String> deletedLiveChatIds,
  ) {
    if (!_selectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          tooltip: 'Export',
          onPressed: () => _showExportDialog(context, comments, liveChats),
        ),
      ];
    }
    return [
      PopupMenuButton<String>(
        onSelected: (value) {
          final notifier = ref.read(deletionSetProvider.notifier);
          if (value == 'select_all_comments') {
            notifier.addAll(comments
                .where((c) => !deletedCommentIds.contains(c.commentId))
                .map((c) => c.commentId));
          } else if (value == 'select_all_chats') {
            notifier.addAll(liveChats
                .where((c) => !deletedLiveChatIds.contains(c.liveChatId))
                .map((c) => c.liveChatId));
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

  void _showExportDialog(
      BuildContext context, List<Comment> comments, List<LiveChat> liveChats) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Export Format'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(exportProvider.notifier).exportData(
                    comments: comments,
                    liveChats: liveChats,
                    format: ExportFormat.csv,
                    filename: 'takeout_export',
                  );
            },
            child: const Text('CSV'),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(exportProvider.notifier).exportData(
                    comments: comments,
                    liveChats: liveChats,
                    format: ExportFormat.json,
                    filename: 'takeout_export',
                  );
            },
            child: const Text('JSON'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentList(
    List<Comment> comments,
    Set<String> selectedIds,
    Set<String> deletedIds,
  ) {
    if (comments.isEmpty) {
      return const EmptyState(
          icon: Icons.comment_outlined, message: 'No comments');
    }
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final isDeleted = deletedIds.contains(comment.commentId);
        return CommentTile(
          comment: comment,
          isSelected: selectedIds.contains(comment.commentId),
          isDeleted: isDeleted,
          selectionMode: _selectionMode,
          onTap: isDeleted
              ? () {}
              : _selectionMode
                  ? () => _toggleSelection(comment.commentId)
                  : () => _showSingleItemActions(
                        context,
                        itemId: comment.commentId,
                        displayText: comment.displayText,
                        isComment: true,
                        videoId: comment.videoId,
                        commentId: comment.commentId,
                      ),
          onLongPress:
              isDeleted ? () {} : () => _enterSelectionMode(comment.commentId),
        );
      },
    );
  }

  Widget _buildLiveChatList(
    List<LiveChat> liveChats,
    Set<String> selectedIds,
    Set<String> deletedIds,
  ) {
    if (liveChats.isEmpty) {
      return const EmptyState(
          icon: Icons.chat_bubble_outline, message: 'No live chats');
    }
    return ListView.builder(
      itemCount: liveChats.length,
      itemBuilder: (context, index) {
        final chat = liveChats[index];
        final isDeleted = deletedIds.contains(chat.liveChatId);
        return LiveChatTile(
          liveChat: chat,
          isSelected: selectedIds.contains(chat.liveChatId),
          isDeleted: isDeleted,
          selectionMode: _selectionMode,
          onTap: isDeleted
              ? () {}
              : _selectionMode
                  ? () => _toggleSelection(chat.liveChatId)
                  : () => _showSingleItemActions(
                        context,
                        itemId: chat.liveChatId,
                        displayText: chat.displayText,
                        isComment: false,
                        videoId: chat.videoId,
                      ),
          onLongPress:
              isDeleted ? () {} : () => _enterSelectionMode(chat.liveChatId),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Single-item actions (tap outside selection mode)
  // ---------------------------------------------------------------------------

  void _showSingleItemActions(
    BuildContext context, {
    required String itemId,
    required String displayText,
    required bool isComment,
    String? videoId,
    String? commentId,
  }) {
    final authenticated = ref.read(isAuthenticatedProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (videoId != null)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open on YouTube'),
                onTap: () {
                  Navigator.pop(ctx);
                  final uri = commentId != null
                      ? Uri.https('www.youtube.com', '/watch', {
                          'v': videoId,
                          'lc': commentId,
                        })
                      : Uri.https('www.youtube.com', '/watch', {
                          'v': videoId,
                        });
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            if (authenticated)
              ListTile(
                leading: const Icon(Icons.cloud_off),
                title: const Text('Delete from YouTube'),
                subtitle: const Text('Permanently removes from your account'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDeletionMethodPicker(
                    context,
                    ref: ref,
                    ids: {itemId},
                    onApiChosen: () =>
                        _enqueueSingle(itemId, displayText, isComment),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove locally'),
              subtitle: const Text('For comments you already deleted outside the app'),
              onTap: () {
                Navigator.pop(ctx);
                _removeLocally({itemId}, isComment);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _enqueueSingle(String itemId, String displayText, bool isComment) {
    final notifier = ref.read(deletionQueueProvider.notifier);
    final snippets = {itemId: displayText};

    if (isComment) {
      notifier.enqueueComments({itemId}, snippets: snippets);
    } else {
      notifier.enqueueLiveChats({itemId}, snippets: snippets);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('1 item queued for deletion'),
        action: SnackBarAction(
          label: 'View Queue',
          onPressed: () => context.router.push(const DeletionQueueRoute()),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bulk deletion bar
  // ---------------------------------------------------------------------------

  Widget _buildDeletionBar(
    BuildContext context,
    Set<String> selectedIds,
    List<Comment> comments,
    List<LiveChat> liveChats,
  ) {
    final authenticated = ref.watch(isAuthenticatedProvider);

    // Split selected IDs by type.
    final commentIdSet = comments.map((c) => c.commentId).toSet();
    final liveChatIdSet = liveChats.map((c) => c.liveChatId).toSet();
    final selectedCommentIds = selectedIds.intersection(commentIdSet);
    final selectedLiveChatIds = selectedIds.intersection(liveChatIdSet);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Tooltip(
                message: 'For items you already deleted outside the app',
                child: FilledButton.icon(
                  onPressed: () => _confirmLocalDelete(
                      context, selectedCommentIds, selectedLiveChatIds),
                  icon: const Icon(Icons.delete_outline),
                  label: Text('Remove ${selectedIds.length} locally'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ),
            if (authenticated) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _confirmApiDelete(
                    context,
                    comments,
                    liveChats,
                    selectedCommentIds,
                    selectedLiveChatIds,
                  ),
                  icon: const Icon(Icons.cloud_off),
                  label: Text('Delete ${selectedIds.length} from YouTube'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmLocalDelete(
    BuildContext context,
    Set<String> commentIds,
    Set<String> liveChatIds,
  ) {
    final total = commentIds.length + liveChatIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Items'),
        content: Text(
            'Remove $total item(s) from the list?\n\n'
            'Use this for items you already deleted manually outside the app. '
            'This does not delete them from YouTube.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (commentIds.isNotEmpty) {
                _removeLocally(commentIds, true);
              }
              if (liveChatIds.isNotEmpty) {
                _removeLocally(liveChatIds, false);
              }
              _exitSelectionMode();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmApiDelete(
    BuildContext context,
    List<Comment> comments,
    List<LiveChat> liveChats,
    Set<String> commentIds,
    Set<String> liveChatIds,
  ) {
    final allIds = {...commentIds, ...liveChatIds};
    showDeletionMethodPicker(
      context,
      ref: ref,
      ids: allIds,
      onApiChosen: () {
        _enqueueSelected(comments, liveChats, commentIds, liveChatIds);
        _exitSelectionMode();
      },
    );
  }

  void _enqueueSelected(
    List<Comment> comments,
    List<LiveChat> liveChats,
    Set<String> commentIds,
    Set<String> liveChatIds,
  ) {
    final notifier = ref.read(deletionQueueProvider.notifier);

    if (commentIds.isNotEmpty) {
      final snippets = <String, String?>{};
      for (final c in comments) {
        if (commentIds.contains(c.commentId)) {
          snippets[c.commentId] = c.displayText;
        }
      }
      notifier.enqueueComments(commentIds, snippets: snippets);
    }

    if (liveChatIds.isNotEmpty) {
      final snippets = <String, String?>{};
      for (final c in liveChats) {
        if (liveChatIds.contains(c.liveChatId)) {
          snippets[c.liveChatId] = c.displayText;
        }
      }
      notifier.enqueueLiveChats(liveChatIds, snippets: snippets);
    }

    final total = commentIds.length + liveChatIds.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$total item(s) queued for deletion'),
        action: SnackBarAction(
          label: 'View Queue',
          onPressed: () => context.router.push(const DeletionQueueRoute()),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _removeLocally(Set<String> ids, bool isComment) async {
    if (isComment) {
      await ref.read(deletedCommentIdsProvider.notifier).markDeleted(ids);
    } else {
      await ref.read(deletedLiveChatIdsProvider.notifier).markDeleted(ids);
    }
  }
}
