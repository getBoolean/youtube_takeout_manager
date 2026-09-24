import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_sticky_collapsable_panel/sliver_sticky_collapsable_panel.dart';

import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/common_widgets/scroll_target_highlight.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/comments/presentation/comment_tile.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/grouped_providers.dart';
import '../../domain/video_group.dart';
import 'channel_item_actions.dart';
import 'header_animation_controller.dart';
import 'scroll_to_tile.dart';
import 'video_group_header.dart';

class ChannelCommentListView extends ConsumerStatefulWidget {
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
  ConsumerState<ChannelCommentListView> createState() =>
      _ChannelCommentListViewState();
}

class _ChannelCommentListViewState extends ConsumerState<ChannelCommentListView>
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
    ref.listen(channelContentSearchQueryProvider, (_, _) {
      setState(() => _visibleCount = _initialVisible);
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(0);
      }
    });
    final query = ref.watch(channelContentSearchQueryProvider);
    final groups = ref.watch(
      filteredGroupedChannelCommentsProvider(widget.channelId),
    );
    final visible = _visibleCount.clamp(0, groups.length);
    return groups.isEmpty
        ? EmptyState(
            icon: query.isEmpty ? Icons.comment_outlined : Icons.search_off,
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
                  highlightCommentId: groups[i].groupKey == _expandGroupKey
                      ? _highlightId
                      : null,
                  onHighlightConsumed: groups[i].groupKey == _expandGroupKey
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
              // Bottom slack so the last group's header has room to
              // fully commit to its compact layout. Without this, a
              // partial shrink near maxScrollExtent would shorten the
              // scroll extent, unpin the header, and bounce the last
              // tile off-screen.
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
          scrollTileBelowHeader(
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
            toggleGroupSelection(ref, groupItemIds, ineligibleIds),
        onLongPress: () {
          selectionMode.value = true;
          toggleGroupSelection(ref, groupItemIds, ineligibleIds);
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
