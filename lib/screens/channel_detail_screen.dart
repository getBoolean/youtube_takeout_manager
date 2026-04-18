import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_sticky_collapsable_panel/sliver_sticky_collapsable_panel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/comment.dart';
import '../models/export_format.dart';
import '../models/live_chat.dart';
import '../models/queue_item_kind.dart';
import '../models/video_group.dart';
import '../providers/auth_providers.dart';
import '../providers/channel_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/deleted_ids_providers.dart';
import '../providers/deletion_providers.dart';
import '../providers/deletion_queue_provider.dart';
import '../providers/export_providers.dart';
import '../providers/grouped_providers.dart';
import '../providers/header_animation_providers.dart';
import '../providers/live_chat_providers.dart';
import '../providers/takeout_providers.dart';
import '../router/app_router.dart';
import '../services/export_service.dart';
import '../widgets/bulk_delete_actions.dart';
import '../widgets/comment_tile.dart';
import '../widgets/debounced_search_bar.dart';
import '../widgets/deletion_method_picker.dart';
import '../widgets/empty_state.dart';
import '../widgets/live_chat_tile.dart';
import '../widgets/queue_snackbar.dart';
import '../widgets/scroll_target_highlight.dart';
import '../widgets/search_options_menu_button.dart';
import '../widgets/select_all_toggle_button.dart';
import '../widgets/selection_action_bar.dart';
import '../widgets/video_group_header.dart';

@RoutePage()
class ChannelDetailScreen extends HookConsumerWidget {
  final String channelId;
  final String? targetKind;
  final String? targetId;

  const ChannelDetailScreen({
    super.key,
    @PathParam('channelId') required this.channelId,
    @QueryParam('targetKind') this.targetKind,
    @QueryParam('targetId') this.targetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionMode = useState(false);
    final commentScrollController = useScrollController();
    final liveChatScrollController = useScrollController();
    final tabController = useTabController(initialLength: 2);

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

    // Resolve scroll target from query params. Split per kind so each list
    // view only sees its own id; the other sees null.
    final isCommentTarget = targetKind == 'comment' && targetId != null;
    final isLiveChatTarget = targetKind == 'liveChat' && targetId != null;
    final commentTargetId = isCommentTarget ? targetId : null;
    final liveChatTargetId = isLiveChatTarget ? targetId : null;

    // One-shot: when arriving with a scroll target, switch to the matching
    // tab. Clearing the per-list search query is handled inside each list
    // view's initState, before its `ref.listen` is registered — so it
    // doesn't fire the search-reset that would undo the scroll target.
    useEffect(() {
      if (!isCommentTarget && !isLiveChatTarget) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tabController.animateTo(isCommentTarget ? 0 : 1);
      });
      return null;
    }, [channelId, targetKind, targetId]);

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
            controller: tabController,
            children: [
              _CommentListView(
                channelId: channelId,
                selectionMode: selectionMode,
                scrollController: commentScrollController,
                initialScrollTarget: commentTargetId,
              ),
              _LiveChatListView(
                channelId: channelId,
                selectionMode: selectionMode,
                scrollController: liveChatScrollController,
                initialScrollTarget: liveChatTargetId,
              ),
            ],
          )
        : hasComments
        ? _CommentListView(
            channelId: channelId,
            selectionMode: selectionMode,
            scrollController: commentScrollController,
            initialScrollTarget: commentTargetId,
          )
        : hasLiveChats
        ? _LiveChatListView(
            channelId: channelId,
            selectionMode: selectionMode,
            scrollController: liveChatScrollController,
            initialScrollTarget: liveChatTargetId,
          )
        : const EmptyState(
            icon: Icons.inbox_outlined,
            message: 'No interactions found',
          );

    return Scaffold(
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
                controller: tabController,
                tabs: [
                  Tab(text: 'Comments ($commentCount)'),
                  Tab(text: 'Live Chats ($liveChatCount)'),
                ],
              )
            : null,
      ),
      body: body,
      bottomNavigationBar: selectionMode.value && hasSelection
          ? _DeletionBar(channelId: channelId, selectionMode: selectionMode)
          : null,
    );
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
    final matchingCommentCount = ref.watch(
      filteredSearchCommentsProvider(channelId).select((l) => l.length),
    );
    final matchingLiveChatCount = ref.watch(
      filteredSearchLiveChatsProvider(channelId).select((l) => l.length),
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
            onSelected: (value) {
              switch (value) {
                case 'delete_all_comments':
                case 'delete_all_chats':
                  _handleChannelDelete(
                    context,
                    ref,
                    value: value,
                    comments: ref.read(channelCommentsProvider(channelId)),
                    liveChats: ref.read(channelLiveChatsProvider(channelId)),
                    skipCommentIds: {
                      ...?ref.read(deletedCommentIdsProvider).value,
                      ...ref.read(queuedCommentIdsProvider),
                      ...ref.read(failedCommentIdsProvider),
                    },
                    skipLiveChatIds: {
                      ...?ref.read(deletedLiveChatIdsProvider).value,
                      ...ref.read(queuedLiveChatIdsProvider),
                      ...ref.read(failedLiveChatIdsProvider),
                    },
                  );
                case 'delete_matching_comments':
                  _handleDeleteSearchResults(
                    context,
                    ref,
                    isComments: true,
                    channelId: channelId,
                  );
                case 'delete_matching_chats':
                  _handleDeleteSearchResults(
                    context,
                    ref,
                    isComments: false,
                    channelId: channelId,
                  );
              }
            },
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
              if (matchingCommentCount > 0)
                PopupMenuItem(
                  value: 'delete_matching_comments',
                  child: Text('Delete $matchingCommentCount matching comments'),
                ),
              if (matchingLiveChatCount > 0)
                PopupMenuItem(
                  value: 'delete_matching_chats',
                  child: Text(
                    'Delete $matchingLiveChatCount matching live chats',
                  ),
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
    final skipCommentIds = {
      ...?ref.watch(deletedCommentIdsProvider).value,
      ...ref.watch(queuedCommentIdsProvider),
      ...ref.watch(failedCommentIdsProvider),
    };
    final skipLiveChatIds = {
      ...?ref.watch(deletedLiveChatIdsProvider).value,
      ...ref.watch(queuedLiveChatIdsProvider),
      ...ref.watch(failedLiveChatIdsProvider),
    };
    final selectableIds = {
      ...comments
          .where((c) => !skipCommentIds.contains(c.commentId))
          .map((c) => c.commentId),
      ...liveChats
          .where((c) => !skipLiveChatIds.contains(c.liveChatId))
          .map((c) => c.liveChatId),
    };
    return SelectAllToggleButton(selectableIds: selectableIds);
  }
}

// =============================================================================
// Body: list views and group slivers
// =============================================================================

class _CommentListView extends ConsumerStatefulWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;
  final String? initialScrollTarget;

  const _CommentListView({
    required this.channelId,
    required this.selectionMode,
    required this.scrollController,
    this.initialScrollTarget,
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
  String? _expandGroupKey;
  String? _highlightId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_maybeGrow);
    _applyInitialScrollTarget();
    if (_highlightId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(suppressHeaderAnimationProvider.notifier).set(active: true);
      });
    }
  }

  void _applyInitialScrollTarget() {
    final target = widget.initialScrollTarget;
    if (target == null) return;
    final groups = ref.read(
      filteredGroupedChannelCommentsProvider(widget.channelId),
    );
    for (var i = 0; i < groups.length; i++) {
      final hit = groups[i].items.any((c) => c.commentId == target);
      if (hit) {
        if (i >= _visibleCount) _visibleCount = i + 1;
        _expandGroupKey = groups[i].groupKey;
        _highlightId = target;
        return;
      }
    }
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
      final total = ref
          .read(filteredGroupedChannelCommentsProvider(widget.channelId))
          .length;
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
    ref.listen(commentSearchQueryProvider, (_, _) {
      setState(() => _visibleCount = _initialVisible);
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(0);
      }
    });
    final query = ref.watch(commentSearchQueryProvider);
    final groups = ref.watch(
      filteredGroupedChannelCommentsProvider(widget.channelId),
    );
    final visible = _visibleCount.clamp(0, groups.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DebouncedSearchBar(
            hintText: 'Search comments...',
            onQueryChanged: (v) =>
                ref.read(commentSearchQueryProvider.notifier).update(v),
            trailing: const [SearchOptionsMenuButton()],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? EmptyState(
                  icon: query.isEmpty
                      ? Icons.comment_outlined
                      : Icons.search_off,
                  message: query.isEmpty ? 'No comments' : 'No results',
                )
              : CustomScrollView(
                  controller: widget.scrollController,
                  slivers: [
                    for (var i = 0; i < visible; i++)
                      _CommentGroupSliver(
                        key: ValueKey('comment-group-${groups[i].groupKey}'),
                        group: groups[i],
                        selectionMode: widget.selectionMode,
                        scrollController: widget.scrollController,
                        highlightQuery: query,
                        // While a scroll target is active, force the target
                        // group expanded and all siblings collapsed so
                        // layout can't shift underneath the scroll. Once
                        // the highlight is consumed we pass null to leave
                        // whatever state the user has set alone.
                        expandInitially: _expandGroupKey == null
                            ? null
                            : groups[i].groupKey == _expandGroupKey,
                        highlightCommentId:
                            groups[i].groupKey == _expandGroupKey
                            ? _highlightId
                            : null,
                        onHighlightConsumed:
                            groups[i].groupKey == _expandGroupKey
                            ? () {
                                if (mounted) {
                                  setState(() {
                                    _highlightId = null;
                                    _expandGroupKey = null;
                                  });
                                }
                              }
                            : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CommentGroupSliver extends HookConsumerWidget {
  final VideoGroup<Comment> group;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;
  final String highlightQuery;

  /// Tri-state: `true` forces the panel expanded on first frame, `false`
  /// forces it collapsed, `null` leaves the user's current state alone.
  /// During a scroll-to-target flow the target group gets `true` and all
  /// other groups get `false`, which removes layout-extent shifts from
  /// sibling panels and makes the scroll deterministic.
  final bool? expandInitially;
  final String? highlightCommentId;
  final VoidCallback? onHighlightConsumed;

  const _CommentGroupSliver({
    super.key,
    required this.group,
    required this.selectionMode,
    required this.scrollController,
    required this.highlightQuery,
    this.expandInitially,
    this.highlightCommentId,
    this.onHighlightConsumed,
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
    final highlightKey = useMemoized(
      () => highlightCommentId == null ? null : GlobalKey(),
      [highlightCommentId],
    );
    final headerKey = useMemoized(
      () => highlightCommentId == null ? null : GlobalKey(),
      [highlightCommentId],
    );

    useEffect(() {
      final force = expandInitially;
      if (force == null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (force && !controller.isExpanded) {
          controller.expandPanel();
        } else if (!force && controller.isExpanded) {
          controller.collapsePanel();
        }
      });
      return null;
    }, [expandInitially]);

    useEffect(() {
      final key = highlightKey;
      if (key == null) return null;
      // Double post-frame so the sibling collapse/expand calls from the
      // `expandInitially` effect above have taken effect and the layout
      // is stable when we compute the scroll offset.
      final suppressHeaderAnimation = ref.read(
        suppressHeaderAnimationProvider.notifier,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollTileBelowHeader(
            key.currentContext,
            headerKey,
            scrollController,
            suppressHeaderAnimation,
          );
        });
      });
      return null;
    }, [highlightKey]);

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
    final queuedIds = ref.watch(queuedCommentIdsProvider);
    final failedIds = ref.watch(failedCommentIdsProvider);
    final ineligibleIds = {...deletedIds, ...queuedIds, ...failedIds};

    return SliverStickyCollapsablePanel(
      scrollController: scrollController,
      panelController: controller,
      headerBuilder: (context, status) => VideoGroupHeader(
        key: headerKey,
        group: group,
        status: status,
        selectionMode: selectionMode.value,
        allSelected: groupSel.all,
        someSelected: groupSel.any && !groupSel.all,
        highlightQuery: highlightQuery,
        // While this group is the scroll-to-target, render the header in
        // its compact layout from the first frame so the panel's scroll
        // extent doesn't shrink when the header pins mid-animation.
        forceCompact: expandInitially == true,
        onToggleGroupSelection: () =>
            _toggleGroupSelection(ref, groupItemIds, ineligibleIds),
        onLongPress: () {
          selectionMode.value = true;
          _toggleGroupSelection(ref, groupItemIds, ineligibleIds);
        },
        onToggleExpanded: () => controller.isExpanded
            ? controller.collapsePanel()
            : controller.expandPanel(),
      ),
      sliverPanel: SliverList.builder(
        itemCount: group.items.length,
        itemBuilder: (context, index) {
          final comment = group.items[index];
          final id = comment.commentId;
          final tile = _CommentTileConsumer(
            comment: comment,
            isDeleted: deletedIds.contains(id),
            isQueued: queuedIds.contains(id),
            isFailed: failedIds.contains(id),
            selectionMode: selectionMode,
            highlightQuery: highlightQuery,
          );
          if (id == highlightCommentId && highlightKey != null) {
            return ScrollTargetHighlight(
              key: highlightKey,
              active: true,
              onComplete: onHighlightConsumed,
              child: tile,
            );
          }
          return tile;
        },
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
          : () => _showSingleItemActions(
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

class _LiveChatListView extends ConsumerStatefulWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;
  final String? initialScrollTarget;

  const _LiveChatListView({
    required this.channelId,
    required this.selectionMode,
    required this.scrollController,
    this.initialScrollTarget,
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
  String? _expandGroupKey;
  String? _highlightId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_maybeGrow);
    _applyInitialScrollTarget();
    if (_highlightId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(suppressHeaderAnimationProvider.notifier).set(active: true);
      });
    }
  }

  void _applyInitialScrollTarget() {
    final target = widget.initialScrollTarget;
    if (target == null) return;
    final groups = ref.read(
      filteredGroupedChannelLiveChatsProvider(widget.channelId),
    );
    for (var i = 0; i < groups.length; i++) {
      final hit = groups[i].items.any((c) => c.liveChatId == target);
      if (hit) {
        if (i >= _visibleCount) _visibleCount = i + 1;
        _expandGroupKey = groups[i].groupKey;
        _highlightId = target;
        return;
      }
    }
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
      final total = ref
          .read(filteredGroupedChannelLiveChatsProvider(widget.channelId))
          .length;
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
    ref.listen(liveChatSearchQueryProvider, (_, _) {
      setState(() => _visibleCount = _initialVisible);
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(0);
      }
    });
    final query = ref.watch(liveChatSearchQueryProvider);
    final groups = ref.watch(
      filteredGroupedChannelLiveChatsProvider(widget.channelId),
    );
    final visible = _visibleCount.clamp(0, groups.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DebouncedSearchBar(
            hintText: 'Search live chats...',
            onQueryChanged: (v) =>
                ref.read(liveChatSearchQueryProvider.notifier).update(v),
            trailing: const [SearchOptionsMenuButton()],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? EmptyState(
                  icon: query.isEmpty
                      ? Icons.chat_bubble_outline
                      : Icons.search_off,
                  message: query.isEmpty ? 'No live chats' : 'No results',
                )
              : CustomScrollView(
                  controller: widget.scrollController,
                  slivers: [
                    for (var i = 0; i < visible; i++)
                      _LiveChatGroupSliver(
                        key: ValueKey('livechat-group-${groups[i].groupKey}'),
                        group: groups[i],
                        selectionMode: widget.selectionMode,
                        scrollController: widget.scrollController,
                        highlightQuery: query,
                        expandInitially: _expandGroupKey == null
                            ? null
                            : groups[i].groupKey == _expandGroupKey,
                        highlightLiveChatId:
                            groups[i].groupKey == _expandGroupKey
                            ? _highlightId
                            : null,
                        onHighlightConsumed:
                            groups[i].groupKey == _expandGroupKey
                            ? () {
                                if (mounted) {
                                  setState(() {
                                    _highlightId = null;
                                    _expandGroupKey = null;
                                  });
                                }
                              }
                            : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LiveChatGroupSliver extends HookConsumerWidget {
  final VideoGroup<LiveChat> group;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;
  final String highlightQuery;

  /// See [_CommentGroupSliver.expandInitially]. Tri-state: `true` forces
  /// expand, `false` forces collapse, `null` leaves user state alone.
  final bool? expandInitially;
  final String? highlightLiveChatId;
  final VoidCallback? onHighlightConsumed;

  const _LiveChatGroupSliver({
    super.key,
    required this.group,
    required this.selectionMode,
    required this.scrollController,
    required this.highlightQuery,
    this.expandInitially,
    this.highlightLiveChatId,
    this.onHighlightConsumed,
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
    final highlightKey = useMemoized(
      () => highlightLiveChatId == null ? null : GlobalKey(),
      [highlightLiveChatId],
    );
    final headerKey = useMemoized(
      () => highlightLiveChatId == null ? null : GlobalKey(),
      [highlightLiveChatId],
    );

    useEffect(() {
      final force = expandInitially;
      if (force == null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (force && !controller.isExpanded) {
          controller.expandPanel();
        } else if (!force && controller.isExpanded) {
          controller.collapsePanel();
        }
      });
      return null;
    }, [expandInitially]);

    useEffect(() {
      final key = highlightKey;
      if (key == null) return null;
      final suppressHeaderAnimation = ref.read(
        suppressHeaderAnimationProvider.notifier,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollTileBelowHeader(
            key.currentContext,
            headerKey,
            scrollController,
            suppressHeaderAnimation,
          );
        });
      });
      return null;
    }, [highlightKey]);

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
    final queuedIds = ref.watch(queuedLiveChatIdsProvider);
    final failedIds = ref.watch(failedLiveChatIdsProvider);
    final ineligibleIds = {...deletedIds, ...queuedIds, ...failedIds};

    return SliverStickyCollapsablePanel(
      scrollController: scrollController,
      panelController: controller,
      headerBuilder: (context, status) => VideoGroupHeader(
        key: headerKey,
        group: group,
        status: status,
        selectionMode: selectionMode.value,
        allSelected: groupSel.all,
        someSelected: groupSel.any && !groupSel.all,
        highlightQuery: highlightQuery,
        forceCompact: expandInitially == true,
        onToggleGroupSelection: () =>
            _toggleGroupSelection(ref, groupItemIds, ineligibleIds),
        onLongPress: () {
          selectionMode.value = true;
          _toggleGroupSelection(ref, groupItemIds, ineligibleIds);
        },
        onToggleExpanded: () => controller.isExpanded
            ? controller.collapsePanel()
            : controller.expandPanel(),
      ),
      sliverPanel: SliverList.builder(
        itemCount: group.items.length,
        itemBuilder: (context, index) {
          final chat = group.items[index];
          final id = chat.liveChatId;
          final tile = _LiveChatTileConsumer(
            chat: chat,
            isDeleted: deletedIds.contains(id),
            isQueued: queuedIds.contains(id),
            isFailed: failedIds.contains(id),
            selectionMode: selectionMode,
            highlightQuery: highlightQuery,
          );
          if (id == highlightLiveChatId && highlightKey != null) {
            return ScrollTargetHighlight(
              key: highlightKey,
              active: true,
              onComplete: onHighlightConsumed,
              child: tile,
            );
          }
          return tile;
        },
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
          : () => _showSingleItemActions(
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

// =============================================================================
// Bottom bar
// =============================================================================

class _DeletionBar extends ConsumerWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;

  const _DeletionBar({required this.channelId, required this.selectionMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(channelCommentsProvider(channelId));
    final liveChats = ref.watch(channelLiveChatsProvider(channelId));
    final selectedIds = ref.watch(deletionSetProvider);

    final selectedCommentIds = <String>{};
    final commentSnippets = <String, String?>{};
    for (final c in comments) {
      if (selectedIds.contains(c.commentId)) {
        selectedCommentIds.add(c.commentId);
        commentSnippets[c.commentId] = c.displayText;
      }
    }
    final selectedLiveChatIds = <String>{};
    final liveChatSnippets = <String, String?>{};
    for (final c in liveChats) {
      if (selectedIds.contains(c.liveChatId)) {
        selectedLiveChatIds.add(c.liveChatId);
        liveChatSnippets[c.liveChatId] = c.displayText;
      }
    }

    return SelectionActionBar(
      commentIds: selectedCommentIds,
      liveChatIds: selectedLiveChatIds,
      commentSnippets: commentSnippets,
      liveChatSnippets: liveChatSnippets,
      onExitSelection: () {
        selectionMode.value = false;
        ref.read(deletionSetProvider.notifier).clear();
      },
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

void _toggleGroupSelection(
  WidgetRef ref,
  Set<String> groupItemIds,
  Set<String> ineligibleIds,
) {
  final eligible = groupItemIds.difference(ineligibleIds);
  if (eligible.isEmpty) return;
  final notifier = ref.read(deletionSetProvider.notifier);
  final selectedIds = ref.read(deletionSetProvider);
  final allSelected = eligible.difference(selectedIds).isEmpty;
  if (allSelected) {
    notifier.removeAll(eligible);
  } else {
    notifier.addAll(eligible);
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
  required QueueItemKind kind,
  String? videoId,
  String? commentId,
  bool isQueued = false,
  bool isFailed = false,
}) {
  final authenticated = ref.read(isAuthenticatedProvider);
  final isComment = kind == QueueItemKind.comment;

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
          if (isFailed)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Retry'),
              subtitle: const Text('Re-queue for deletion'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(deletionQueueProvider.notifier)
                    .retryByItemId(itemId, kind);
              },
            ),
          if (isQueued || isFailed)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Remove from queue'),
              subtitle: const Text('Cancel the pending deletion'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(deletionQueueProvider.notifier)
                    .removeByItemId(itemId, kind);
              },
            )
          else if (authenticated)
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
          if (!isQueued && !isFailed)
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
                          if (isComment) {
                            ref
                                .read(deletedCommentIdsProvider.notifier)
                                .markDeleted({itemId});
                          } else {
                            ref
                                .read(deletedLiveChatIdsProvider.notifier)
                                .markDeleted({itemId});
                          }
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
  required Set<String> skipCommentIds,
  required Set<String> skipLiveChatIds,
}) {
  if (value == 'delete_all_comments') {
    bulkDeleteViaPicker(
      context,
      ref,
      commentSnippets: {
        for (final c in comments)
          if (!skipCommentIds.contains(c.commentId)) c.commentId: c.displayText,
      },
      liveChatSnippets: const {},
    );
  } else {
    bulkDeleteViaPicker(
      context,
      ref,
      commentSnippets: const {},
      liveChatSnippets: {
        for (final c in liveChats)
          if (!skipLiveChatIds.contains(c.liveChatId))
            c.liveChatId: c.displayText,
      },
    );
  }
}

void _handleDeleteSearchResults(
  BuildContext context,
  WidgetRef ref, {
  required bool isComments,
  required String channelId,
}) {
  if (isComments) {
    final matches = ref.read(filteredSearchCommentsProvider(channelId));
    final skip = {
      ...?ref.read(deletedCommentIdsProvider).value,
      ...ref.read(queuedCommentIdsProvider),
      ...ref.read(failedCommentIdsProvider),
    };
    bulkDeleteViaPicker(
      context,
      ref,
      commentSnippets: {
        for (final c in matches)
          if (!skip.contains(c.commentId)) c.commentId: c.displayText,
      },
      liveChatSnippets: const {},
    );
  } else {
    final matches = ref.read(filteredSearchLiveChatsProvider(channelId));
    final skip = {
      ...?ref.read(deletedLiveChatIdsProvider).value,
      ...ref.read(queuedLiveChatIdsProvider),
      ...ref.read(failedLiveChatIdsProvider),
    };
    bulkDeleteViaPicker(
      context,
      ref,
      commentSnippets: const {},
      liveChatSnippets: {
        for (final c in matches)
          if (!skip.contains(c.liveChatId)) c.liveChatId: c.displayText,
      },
    );
  }
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

  showQueuedForDeletionSnackBar(
    context,
    ref,
    message: '1 item queued for deletion',
  );
}


/// Scrolls [scrollController] so the widget at [tileContext] lands just below
/// the sticky [VideoGroupHeader] instead of being hidden behind it.
///
/// The target group is built with [VideoGroupHeader.forceCompact] and its
/// siblings are pre-collapsed, so every header is already at its compact
/// height from the first frame — the panel's scroll extent can't shrink
/// during the animation. That makes a single `animateTo` land on exactly
/// the right offset without any follow-up correction. The offset is the
/// target header's measured height plus a 12px gap, so tiles stay visible
/// below the pinned header even when the title wraps to two lines.
Future<void> _scrollTileBelowHeader(
  BuildContext? tileContext,
  GlobalKey? headerKey,
  ScrollController scrollController,
  SuppressHeaderAnimation suppressHeaderAnimation,
) async {
  if (tileContext == null || !tileContext.mounted) return;
  if (!scrollController.hasClients) return;
  final tileBox = tileContext.findRenderObject();
  if (tileBox is! RenderBox || !tileBox.hasSize) return;

  const gap = 12.0;
  final headerBox = headerKey?.currentContext?.findRenderObject();
  final headerHeight = (headerBox is RenderBox && headerBox.hasSize)
      ? headerBox.size.height
      : 104.0;
  final targetPixelOffset = headerHeight + gap;

  suppressHeaderAnimation.set(active: true);
  try {
    final revealOffset = RenderAbstractViewport.of(
      tileBox,
    ).getOffsetToReveal(tileBox, 0.0).offset;
    final position = scrollController.position;
    final target = (revealOffset - targetPixelOffset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - scrollController.offset).abs() < 0.5) return;
    await scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  } finally {
    suppressHeaderAnimation.set(active: false);
  }
}
