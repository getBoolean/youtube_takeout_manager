import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_sticky_collapsable_panel/sliver_sticky_collapsable_panel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/comment.dart';
import '../models/export_format.dart';
import '../models/live_chat.dart';
import '../models/video_group.dart';
import '../providers/auth_providers.dart';
import '../providers/channel_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/deleted_ids_providers.dart';
import '../providers/deletion_providers.dart';
import '../providers/deletion_queue_provider.dart';
import '../providers/export_providers.dart';
import '../providers/grouped_providers.dart';
import '../providers/live_chat_providers.dart';
import '../providers/takeout_providers.dart';
import '../router/app_router.dart';
import '../services/export_service.dart';
import '../widgets/comment_tile.dart';
import '../widgets/deletion_method_picker.dart';
import '../widgets/empty_state.dart';
import '../widgets/live_chat_tile.dart';
import '../widgets/video_group_header.dart';

@RoutePage()
class ChannelDetailScreen extends HookConsumerWidget {
  final String channelId;

  const ChannelDetailScreen({
    super.key,
    @PathParam('channelId') required this.channelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionMode = useState(false);
    final commentScrollController = useScrollController();
    final liveChatScrollController = useScrollController();

    // Deep-link guard: ensure back navigation lands somewhere sensible.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.router.canPop()) {
          context.router.replaceAll([
            const HomeRoute(),
            const ChannelListRoute(),
            ChannelDetailRoute(channelId: channelId),
          ]);
        }
      });
      return null;
    }, const []);

    final takeoutAsync = ref.watch(takeoutProvider);
    if (takeoutAsync.isLoading ||
        (!takeoutAsync.hasValue && !takeoutAsync.hasError)) {
      return const _LoadingSkeleton();
    }

    final commentCount = ref.watch(
      channelCommentsProvider(channelId).select((l) => l.length),
    );
    final liveChatCount = ref.watch(
      channelLiveChatsProvider(channelId).select((l) => l.length),
    );
    final hasSelection = ref.watch(
      deletionSetProvider.select((s) => s.isNotEmpty),
    );
    final channel = ref.watch(channelByIdProvider(channelId));
    final channelName = channel?.channelTitle ?? 'Unknown Channel';

    final hasComments = commentCount > 0;
    final hasLiveChats = liveChatCount > 0;
    final useTabs = hasComments && hasLiveChats;

    final body = useTabs
        ? TabBarView(
            children: [
              _CommentListView(
                channelId: channelId,
                selectionMode: selectionMode,
                scrollController: commentScrollController,
              ),
              _LiveChatListView(
                channelId: channelId,
                selectionMode: selectionMode,
                scrollController: liveChatScrollController,
              ),
            ],
          )
        : hasComments
        ? _CommentListView(
            channelId: channelId,
            selectionMode: selectionMode,
            scrollController: commentScrollController,
          )
        : hasLiveChats
        ? _LiveChatListView(
            channelId: channelId,
            selectionMode: selectionMode,
            scrollController: liveChatScrollController,
          )
        : const EmptyState(
            icon: Icons.inbox_outlined,
            message: 'No interactions found',
          );

    final scaffold = Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _ChannelTitle(
          channelName: channelName,
          thumbnailUrl: channel?.thumbnailUrl,
        ),
        leading: selectionMode.value
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  selectionMode.value = false;
                  ref.read(deletionSetProvider.notifier).clear();
                },
              )
            : !context.router.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.router.replaceAll([
                  const HomeRoute(),
                  const ChannelListRoute(),
                ]),
              )
            : null,
        actions: [
          _ChannelAppBarActions(
            channelId: channelId,
            channelUrl: channel?.channelUrl,
            selectionMode: selectionMode,
          ),
        ],
        bottom: useTabs
            ? TabBar(
                tabs: [
                  Tab(text: 'Comments ($commentCount)'),
                  Tab(text: 'Live Chats ($liveChatCount)'),
                ],
              )
            : null,
      ),
      body: body,
      bottomNavigationBar: selectionMode.value && hasSelection
          ? _DeletionBar(
              channelId: channelId,
              selectionMode: selectionMode,
            )
          : null,
    );

    return useTabs
        ? DefaultTabController(length: 2, child: scaffold)
        : scaffold;
  }
}

// =============================================================================
// AppBar pieces
// =============================================================================

class _ChannelTitle extends StatelessWidget {
  final String channelName;
  final String? thumbnailUrl;

  const _ChannelTitle({required this.channelName, this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: thumbnailUrl != null
              ? ClipOval(
                  child: Image.network(
                    thumbnailUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  ),
                )
              : Text(
                  channelName[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 14,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(channelName, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _ChannelAppBarActions extends ConsumerWidget {
  final String channelId;
  final String? channelUrl;
  final ValueNotifier<bool> selectionMode;

  const _ChannelAppBarActions({
    required this.channelId,
    required this.channelUrl,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectionMode.value) {
      return _SelectAllAction(channelId: channelId);
    }

    final channel = ref.watch(channelByIdProvider(channelId));
    final channelName = channel?.channelTitle ?? 'Unknown Channel';
    final authenticated = ref.watch(isAuthenticatedProvider);
    final hasComments = ref.watch(
      channelCommentsProvider(channelId).select((l) => l.isNotEmpty),
    );
    final hasLiveChats = ref.watch(
      channelLiveChatsProvider(channelId).select((l) => l.isNotEmpty),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.open_in_new),
          tooltip: 'Open on YouTube',
          onPressed: () {
            final url =
                channelUrl ?? 'https://www.youtube.com/channel/$channelId';
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          },
        ),
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          tooltip: 'Export',
          onPressed: () => _showExportSheet(
            context,
            ref,
            channelId: channelId,
            channelName: channelName,
            comments: ref.read(channelCommentsProvider(channelId)),
            liveChats: ref.read(channelLiveChatsProvider(channelId)),
          ),
        ),
        if (authenticated)
          PopupMenuButton<String>(
            onSelected: (value) => _handleChannelDelete(
              context,
              ref,
              value: value,
              comments: ref.read(channelCommentsProvider(channelId)),
              liveChats: ref.read(channelLiveChatsProvider(channelId)),
              deletedCommentIds:
                  ref.read(deletedCommentIdsProvider).value ?? {},
              deletedLiveChatIds:
                  ref.read(deletedLiveChatIdsProvider).value ?? {},
            ),
            itemBuilder: (_) => [
              if (hasComments)
                const PopupMenuItem(
                  value: 'delete_all_comments',
                  child: Text('Delete All Comments from Channel'),
                ),
              if (hasLiveChats)
                const PopupMenuItem(
                  value: 'delete_all_chats',
                  child: Text('Delete All Live Chats from Channel'),
                ),
            ],
          ),
      ],
    );
  }
}

class _SelectAllAction extends ConsumerWidget {
  final String channelId;

  const _SelectAllAction({required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(channelCommentsProvider(channelId));
    final liveChats = ref.watch(channelLiveChatsProvider(channelId));
    final deletedCommentIds = ref.watch(deletedCommentIdsProvider).value ?? {};
    final deletedLiveChatIds =
        ref.watch(deletedLiveChatIdsProvider).value ?? {};
    final selectableIds = {
      ...comments
          .where((c) => !deletedCommentIds.contains(c.commentId))
          .map((c) => c.commentId),
      ...liveChats
          .where((c) => !deletedLiveChatIds.contains(c.liveChatId))
          .map((c) => c.liveChatId),
    };
    final selectedIds = ref.watch(deletionSetProvider);
    final allSelected =
        selectableIds.isNotEmpty &&
        selectableIds.difference(selectedIds).isEmpty;

    return IconButton(
      icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
      tooltip: allSelected ? 'Deselect All' : 'Select All',
      onPressed: () {
        final notifier = ref.read(deletionSetProvider.notifier);
        if (allSelected) {
          notifier.clear();
        } else {
          notifier.addAll(selectableIds);
        }
      },
    );
  }
}

// =============================================================================
// Body: list views and group slivers
// =============================================================================

class _CommentListView extends ConsumerStatefulWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;

  const _CommentListView({
    required this.channelId,
    required this.selectionMode,
    required this.scrollController,
  });

  @override
  ConsumerState<_CommentListView> createState() => _CommentListViewState();
}

class _CommentListViewState extends ConsumerState<_CommentListView>
    with AutomaticKeepAliveClientMixin {
  static const int _initialVisible = 15;
  static const int _growBy = 10;
  static const double _growThreshold = 400;

  int _visibleCount = _initialVisible;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_maybeGrow);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_maybeGrow);
    super.dispose();
  }

  void _maybeGrow() {
    if (!widget.scrollController.hasClients) return;
    final pos = widget.scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _growThreshold) {
      final total =
          ref.read(groupedChannelCommentsProvider(widget.channelId)).length;
      if (_visibleCount < total) {
        setState(() {
          _visibleCount = (_visibleCount + _growBy).clamp(0, total);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final groups = ref.watch(groupedChannelCommentsProvider(widget.channelId));
    if (groups.isEmpty) {
      return const EmptyState(
        icon: Icons.comment_outlined,
        message: 'No comments',
      );
    }
    final visible = _visibleCount.clamp(0, groups.length);
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        for (var i = 0; i < visible; i++)
          _CommentGroupSliver(
            key: ValueKey('comment-group-${groups[i].groupKey}'),
            group: groups[i],
            selectionMode: widget.selectionMode,
            scrollController: widget.scrollController,
          ),
      ],
    );
  }
}

class _CommentGroupSliver extends HookConsumerWidget {
  final VideoGroup<Comment> group;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;

  const _CommentGroupSliver({
    super.key,
    required this.group,
    required this.selectionMode,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Controller lives and dies with this widget instance. The SliverStickyCollapsablePanel
    // below is its sole child and owns disposal on unmount, so we never dispose ourselves.
    final controller = useMemoized(
      () => StickyCollapsablePanelController(key: group.groupKey),
    );
    final groupItemIds = useMemoized(
      () => group.items.map((c) => c.commentId).toSet(),
      [group],
    );

    final groupSel = ref.watch(
      deletionSetProvider.select((s) {
        var hits = 0;
        for (final id in groupItemIds) {
          if (s.contains(id)) hits++;
        }
        return (
          all: groupItemIds.isNotEmpty && hits == groupItemIds.length,
          any: hits > 0,
        );
      }),
    );
    final deletedIds = ref.watch(deletedCommentIdsProvider).value ?? const {};

    return SliverStickyCollapsablePanel(
      scrollController: scrollController,
      panelController: controller,
      headerBuilder: (context, status) => VideoGroupHeader(
        group: group,
        status: status,
        selectionMode: selectionMode.value,
        allSelected: groupSel.all,
        someSelected: groupSel.any && !groupSel.all,
        onToggleGroupSelection: () =>
            _toggleGroupSelection(ref, groupItemIds),
      ),
      sliverPanel: SliverList.builder(
        itemCount: group.items.length,
        itemBuilder: (context, index) {
          final comment = group.items[index];
          final isDeleted = deletedIds.contains(comment.commentId);
          return _CommentTileConsumer(
            comment: comment,
            isDeleted: isDeleted,
            selectionMode: selectionMode,
          );
        },
      ),
    );
  }
}

class _CommentTileConsumer extends ConsumerWidget {
  final Comment comment;
  final bool isDeleted;
  final ValueNotifier<bool> selectionMode;

  const _CommentTileConsumer({
    required this.comment,
    required this.isDeleted,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      deletionSetProvider.select((s) => s.contains(comment.commentId)),
    );
    return CommentTile(
      comment: comment,
      isSelected: isSelected,
      isDeleted: isDeleted,
      selectionMode: selectionMode.value,
      onTap: isDeleted
          ? () {}
          : selectionMode.value
          ? () =>
                ref.read(deletionSetProvider.notifier).toggle(comment.commentId)
          : () => _showSingleItemActions(
              context,
              ref,
              itemId: comment.commentId,
              displayText: comment.displayText,
              isComment: true,
              videoId: comment.videoId,
              commentId: comment.commentId,
            ),
      onLongPress: isDeleted
          ? () {}
          : () {
              selectionMode.value = true;
              ref.read(deletionSetProvider.notifier).toggle(comment.commentId);
            },
    );
  }
}

class _LiveChatListView extends ConsumerStatefulWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;

  const _LiveChatListView({
    required this.channelId,
    required this.selectionMode,
    required this.scrollController,
  });

  @override
  ConsumerState<_LiveChatListView> createState() => _LiveChatListViewState();
}

class _LiveChatListViewState extends ConsumerState<_LiveChatListView>
    with AutomaticKeepAliveClientMixin {
  static const int _initialVisible = 15;
  static const int _growBy = 10;
  static const double _growThreshold = 400;

  int _visibleCount = _initialVisible;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_maybeGrow);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_maybeGrow);
    super.dispose();
  }

  void _maybeGrow() {
    if (!widget.scrollController.hasClients) return;
    final pos = widget.scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _growThreshold) {
      final total =
          ref.read(groupedChannelLiveChatsProvider(widget.channelId)).length;
      if (_visibleCount < total) {
        setState(() {
          _visibleCount = (_visibleCount + _growBy).clamp(0, total);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final groups = ref.watch(groupedChannelLiveChatsProvider(widget.channelId));
    if (groups.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        message: 'No live chats',
      );
    }
    final visible = _visibleCount.clamp(0, groups.length);
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        for (var i = 0; i < visible; i++)
          _LiveChatGroupSliver(
            key: ValueKey('livechat-group-${groups[i].groupKey}'),
            group: groups[i],
            selectionMode: widget.selectionMode,
            scrollController: widget.scrollController,
          ),
      ],
    );
  }
}

class _LiveChatGroupSliver extends HookConsumerWidget {
  final VideoGroup<LiveChat> group;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;

  const _LiveChatGroupSliver({
    super.key,
    required this.group,
    required this.selectionMode,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(
      () => StickyCollapsablePanelController(key: group.groupKey),
    );
    final groupItemIds = useMemoized(
      () => group.items.map((c) => c.liveChatId).toSet(),
      [group],
    );

    final groupSel = ref.watch(
      deletionSetProvider.select((s) {
        var hits = 0;
        for (final id in groupItemIds) {
          if (s.contains(id)) hits++;
        }
        return (
          all: groupItemIds.isNotEmpty && hits == groupItemIds.length,
          any: hits > 0,
        );
      }),
    );
    final deletedIds = ref.watch(deletedLiveChatIdsProvider).value ?? const {};

    return SliverStickyCollapsablePanel(
      scrollController: scrollController,
      panelController: controller,
      headerBuilder: (context, status) => VideoGroupHeader(
        group: group,
        status: status,
        selectionMode: selectionMode.value,
        allSelected: groupSel.all,
        someSelected: groupSel.any && !groupSel.all,
        onToggleGroupSelection: () =>
            _toggleGroupSelection(ref, groupItemIds),
      ),
      sliverPanel: SliverList.builder(
        itemCount: group.items.length,
        itemBuilder: (context, index) {
          final chat = group.items[index];
          final isDeleted = deletedIds.contains(chat.liveChatId);
          return _LiveChatTileConsumer(
            chat: chat,
            isDeleted: isDeleted,
            selectionMode: selectionMode,
          );
        },
      ),
    );
  }
}

class _LiveChatTileConsumer extends ConsumerWidget {
  final LiveChat chat;
  final bool isDeleted;
  final ValueNotifier<bool> selectionMode;

  const _LiveChatTileConsumer({
    required this.chat,
    required this.isDeleted,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(
      deletionSetProvider.select((s) => s.contains(chat.liveChatId)),
    );
    return LiveChatTile(
      liveChat: chat,
      isSelected: isSelected,
      isDeleted: isDeleted,
      selectionMode: selectionMode.value,
      onTap: isDeleted
          ? () {}
          : selectionMode.value
          ? () =>
                ref.read(deletionSetProvider.notifier).toggle(chat.liveChatId)
          : () => _showSingleItemActions(
              context,
              ref,
              itemId: chat.liveChatId,
              displayText: chat.displayText,
              isComment: false,
              videoId: chat.videoId,
            ),
      onLongPress: isDeleted
          ? () {}
          : () {
              selectionMode.value = true;
              ref.read(deletionSetProvider.notifier).toggle(chat.liveChatId);
            },
    );
  }
}

// =============================================================================
// Bottom bar
// =============================================================================

class _DeletionBar extends ConsumerWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;

  const _DeletionBar({
    required this.channelId,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticated = ref.watch(isAuthenticatedProvider);
    final comments = ref.watch(channelCommentsProvider(channelId));
    final liveChats = ref.watch(channelLiveChatsProvider(channelId));
    final selectedIds = ref.watch(deletionSetProvider);

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
                    context,
                    ref,
                    selectionMode: selectionMode,
                    commentIds: selectedCommentIds,
                    liveChatIds: selectedLiveChatIds,
                  ),
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
                    ref,
                    selectionMode: selectionMode,
                    comments: comments,
                    liveChats: liveChats,
                    commentIds: selectedCommentIds,
                    liveChatIds: selectedLiveChatIds,
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
}

// =============================================================================
// Loading state
// =============================================================================

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skeletonColor = theme.colorScheme.surfaceContainerHighest;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: !context.router.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.router.replaceAll([
                  const HomeRoute(),
                  const ChannelListRoute(),
                ]),
              )
            : null,
        title: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: skeletonColor),
            const SizedBox(width: 12),
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 16, backgroundColor: skeletonColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Ephemeral action handlers (modal sheets, dialogs). Not stateful; kept as
// file-scope functions because they operate on Navigator/ref, not widget state.
// =============================================================================

void _toggleGroupSelection(WidgetRef ref, Set<String> groupItemIds) {
  final notifier = ref.read(deletionSetProvider.notifier);
  final selectedIds = ref.read(deletionSetProvider);
  final allSelected = groupItemIds.difference(selectedIds).isEmpty;
  if (allSelected) {
    notifier.removeAll(groupItemIds);
  } else {
    notifier.addAll(groupItemIds);
  }
}

void _showExportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String channelId,
  required String channelName,
  required List<Comment> comments,
  required List<LiveChat> liveChats,
}) {
  final filename = ExportService.sanitizeFilename('${channelName}_export');
  final channelNames = {channelId: channelName};

  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Export Data',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export as CSV'),
            subtitle: const Text('Comma-separated values (.csv)'),
            onTap: () {
              Navigator.pop(ctx);
              _doExport(
                context,
                ref,
                format: ExportFormat.csv,
                filename: filename,
                comments: comments,
                liveChats: liveChats,
                channelNames: channelNames,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('Export as JSON'),
            subtitle: const Text('Structured data (.json)'),
            onTap: () {
              Navigator.pop(ctx);
              _doExport(
                context,
                ref,
                format: ExportFormat.json,
                filename: filename,
                comments: comments,
                liveChats: liveChats,
                channelNames: channelNames,
              );
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _doExport(
  BuildContext context,
  WidgetRef ref, {
  required ExportFormat format,
  required String filename,
  required List<Comment> comments,
  required List<LiveChat> liveChats,
  required Map<String, String> channelNames,
}) async {
  final ext = format == ExportFormat.csv ? 'csv' : 'json';
  final result = await ref
      .read(exportProvider.notifier)
      .exportData(
        comments: comments,
        liveChats: liveChats,
        format: format,
        filename: filename,
        channelNames: channelNames,
      );

  if (!context.mounted) return;

  switch (result) {
    case ExportResult.success:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported $filename.$ext')));
    case ExportResult.error:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export failed')));
    case ExportResult.cancelled:
      break;
  }
}

void _showSingleItemActions(
  BuildContext context,
  WidgetRef ref, {
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
                    : Uri.https('www.youtube.com', '/watch', {'v': videoId});
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
                  onApiChosen: () => _enqueueSingle(
                    context,
                    ref,
                    itemId: itemId,
                    displayText: displayText,
                    isComment: isComment,
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Remove locally'),
            subtitle: const Text(
              'For comments you already deleted outside the app',
            ),
            onTap: () {
              Navigator.pop(ctx);
              showDialog<void>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Remove locally?'),
                  content: const Text(
                    'This only removes the item from your list. '
                    'It does not delete it from YouTube.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _removeLocally(ref, {itemId}, isComment);
                      },
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

void _handleChannelDelete(
  BuildContext context,
  WidgetRef ref, {
  required String value,
  required List<Comment> comments,
  required List<LiveChat> liveChats,
  required Set<String> deletedCommentIds,
  required Set<String> deletedLiveChatIds,
}) {
  final isComments = value == 'delete_all_comments';
  final items = isComments
      ? comments.where((c) => !deletedCommentIds.contains(c.commentId)).toList()
      : liveChats
            .where((c) => !deletedLiveChatIds.contains(c.liveChatId))
            .toList();
  final label = isComments ? 'comments' : 'live chats';

  if (items.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('No $label to delete')));
    return;
  }

  final ids = isComments
      ? items.cast<Comment>().map((c) => c.commentId).toSet()
      : items.cast<LiveChat>().map((c) => c.liveChatId).toSet();
  showDeletionMethodPicker(
    context,
    ref: ref,
    ids: ids,
    onApiChosen: () {
      final notifier = ref.read(deletionQueueProvider.notifier);
      if (isComments) {
        final snippets = <String, String?>{
          for (final c in items.cast<Comment>()) c.commentId: c.displayText,
        };
        notifier.enqueueComments(ids, snippets: snippets);
      } else {
        final snippets = <String, String?>{
          for (final c in items.cast<LiveChat>()) c.liveChatId: c.displayText,
        };
        notifier.enqueueLiveChats(ids, snippets: snippets);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ids.length} $label queued for deletion'),
          action: SnackBarAction(
            label: 'View Queue',
            onPressed: () => context.router.push(const DeletionQueueRoute()),
          ),
        ),
      );
    },
  );
}

void _enqueueSingle(
  BuildContext context,
  WidgetRef ref, {
  required String itemId,
  required String displayText,
  required bool isComment,
}) {
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

void _confirmLocalDelete(
  BuildContext context,
  WidgetRef ref, {
  required ValueNotifier<bool> selectionMode,
  required Set<String> commentIds,
  required Set<String> liveChatIds,
}) {
  final total = commentIds.length + liveChatIds.length;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove Items'),
      content: Text(
        'Remove $total item(s) from the list?\n\n'
        'Use this for items you already deleted manually outside the app. '
        'This does not delete them from YouTube.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            if (commentIds.isNotEmpty) {
              _removeLocally(ref, commentIds, true);
            }
            if (liveChatIds.isNotEmpty) {
              _removeLocally(ref, liveChatIds, false);
            }
            selectionMode.value = false;
            ref.read(deletionSetProvider.notifier).clear();
          },
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

void _confirmApiDelete(
  BuildContext context,
  WidgetRef ref, {
  required ValueNotifier<bool> selectionMode,
  required List<Comment> comments,
  required List<LiveChat> liveChats,
  required Set<String> commentIds,
  required Set<String> liveChatIds,
}) {
  final allIds = {...commentIds, ...liveChatIds};
  showDeletionMethodPicker(
    context,
    ref: ref,
    ids: allIds,
    onApiChosen: () {
      _enqueueSelected(
        context,
        ref,
        comments: comments,
        liveChats: liveChats,
        commentIds: commentIds,
        liveChatIds: liveChatIds,
      );
      selectionMode.value = false;
      ref.read(deletionSetProvider.notifier).clear();
    },
  );
}

void _enqueueSelected(
  BuildContext context,
  WidgetRef ref, {
  required List<Comment> comments,
  required List<LiveChat> liveChats,
  required Set<String> commentIds,
  required Set<String> liveChatIds,
}) {
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

Future<void> _removeLocally(
  WidgetRef ref,
  Set<String> ids,
  bool isComment,
) async {
  if (isComment) {
    await ref.read(deletedCommentIdsProvider.notifier).markDeleted(ids);
  } else {
    await ref.read(deletedLiveChatIdsProvider.notifier).markDeleted(ids);
  }
}
