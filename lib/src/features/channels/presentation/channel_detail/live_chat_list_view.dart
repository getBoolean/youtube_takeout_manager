import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_sticky_collapsable_panel/sliver_sticky_collapsable_panel.dart';

import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/common_widgets/scroll_target_highlight.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/presentation/live_chat_tile.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/grouped_providers.dart';
import '../../domain/video_group.dart';
import 'channel_item_actions.dart';
import 'header_animation_controller.dart';
import 'scroll_to_tile.dart';
import 'video_group_header.dart';

class ChannelLiveChatListView extends ConsumerStatefulWidget {
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
  ConsumerState<ChannelLiveChatListView> createState() =>
      _ChannelLiveChatListViewState();
}

class _ChannelLiveChatListViewState
    extends ConsumerState<ChannelLiveChatListView>
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
    ref.listen(channelContentSearchQueryProvider, (_, _) {
      setState(() => _visibleCount = _initialVisible);
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(0);
      }
    });
    final query = ref.watch(channelContentSearchQueryProvider);
    final groups = ref.watch(
      filteredGroupedChannelLiveChatsProvider(widget.channelId),
    );
    final visible = _visibleCount.clamp(0, groups.length);
    return groups.isEmpty
        ? EmptyState(
            icon: query.isEmpty ? Icons.chat_bubble_outline : Icons.search_off,
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
                  highlightLiveChatId: groups[i].groupKey == _expandGroupKey
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
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
  }
}

class _LiveChatGroupSliver extends HookConsumerWidget {
  final VideoGroup<LiveChat> group;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;
  final String highlightQuery;

  /// Same as the comment group sliver. Tri-state: `true` forces
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
