import 'dart:math' as math;

import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' show nearEqual, nearZero;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/scroll_target_highlight.dart';
import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import '../../application/channel_content_search_query.dart';
import '../../domain/video_group.dart';
import 'channel_item_actions.dart';
import 'header_animation_controller.dart';
import 'video_group_header.dart';

typedef VideoGroupTileBuilder<T> =
    Widget Function(
      BuildContext context,
      T item, {
      required bool isDeleted,
      required bool isQueued,
      required bool isFailed,
    });

/// Groups loaded before a scroll target is resolved; all but the target's
/// group are collapsed so the jump lands on a stable layout.
const _targetSiblingWindow = 15;

/// A channel's comments or live chats grouped by video, with sticky headers
/// that morph from large to compact as they pin.
class VideoGroupListView<T> extends HookConsumerWidget {
  final List<VideoGroup<T>> groups;
  final String Function(T item) itemId;
  final VideoGroupTileBuilder<T> tileBuilder;
  final Set<String> deletedIds;
  final Set<String> queuedIds;
  final Set<String> failedIds;
  final ValueNotifier<bool> selectionMode;
  final ScrollController scrollController;
  final String? initialScrollTarget;

  const VideoGroupListView({
    super.key,
    required this.groups,
    required this.itemId,
    required this.tileBuilder,
    required this.deletedIds,
    required this.queuedIds,
    required this.failedIds,
    required this.selectionMode,
    required this.scrollController,
    this.initialScrollTarget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(StickyGroupedListController.new);
    useEffect(() => controller.dispose, [controller]);

    // Resolved once: the group holding the initial scroll target.
    final target = useMemoized(() {
      final id = initialScrollTarget;
      if (id == null) return null;
      for (var g = 0; g < groups.length; g++) {
        if (groups[g].items.any((item) => itemId(item) == id)) {
          return (index: g, key: groups[g].groupKey, itemId: id);
        }
      }
      return null;
    });
    final highlightId = useState(target?.itemId);
    // While the jump is in flight the target header stays compact.
    final forcedCompactKey = useState(target?.key);

    useEffect(() {
      if (target == null) return null;
      final suppress = ref.read(suppressHeaderAnimationProvider.notifier);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        suppress.set(active: true);
        controller.collapseAll([
          for (final group in groups.take(
            math.max(_targetSiblingWindow, target.index + 1),
          ))
            if (group.groupKey != target.key) group.groupKey,
        ]);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await controller.revealItem(
              target.itemId,
              gap: 12,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          } finally {
            suppress.set(active: false);
          }
        });
      });
      return null;
    }, const []);

    useValueChanged<String?, void>(
      forcedCompactKey.value,
      (_, _) => controller.refreshHeaderStates(),
    );

    ref.listen(channelContentSearchQueryProvider, (_, _) {
      if (scrollController.hasClients) scrollController.jumpTo(0);
    });
    final query = ref.watch(channelContentSearchQueryProvider);

    // Matches sliver_sticky_collapsable_panel, which snapped the scroll
    // percentage to 0 or 1 within one physical pixel's worth of ratio.
    final tolerance = 1 / MediaQuery.devicePixelRatioOf(context);
    bool isCompact(VideoGroup<T> group, StickyHeaderStatus status) {
      var scrolled = status.scrollPercentage;
      if (nearZero(scrolled, tolerance)) {
        scrolled = 0;
      } else if (nearEqual(1, scrolled, tolerance)) {
        scrolled = 1;
      }
      return group.groupKey == forcedCompactKey.value ||
          status.isPinned ||
          !status.isExpanded ||
          scrolled >= 1;
    }

    final ineligibleIds = {...deletedIds, ...queuedIds, ...failedIds};

    return StickyGroupedListView<VideoGroup<T>, T, CueController>(
      groups: groups,
      groupKey: (group) => group.groupKey,
      itemsOf: (group) => group.items,
      itemKey: (item) => itemId(item),
      controller: controller,
      scrollController: scrollController,
      keepAlive: true,
      // Room for the last group's header to settle into its compact layout.
      trailing: const SliverToBoxAdapter(child: SizedBox(height: 80)),
      createHeaderState: (group, status, vsync) => CueController(
        vsync: vsync,
        motion: const Spring.smooth(),
        value: isCompact(group, status) ? 1 : 0,
      ),
      updateHeaderState: (group, motion, status) {
        final compact = isCompact(group, status);
        final instant =
            group.groupKey == forcedCompactKey.value ||
            ref.read(suppressHeaderAnimationProvider);
        if (instant) {
          motion.value = compact ? 1 : 0;
        } else if (compact) {
          motion.forward();
        } else {
          motion.reverse();
        }
      },
      disposeHeaderState: (motion) => motion.dispose(),
      headerBuilder: (context, group, motion, status) => _GroupHeader<T>(
        group: group,
        itemId: itemId,
        compactMotion: motion,
        isExpanded: status.isExpanded,
        selectionMode: selectionMode,
        ineligibleIds: ineligibleIds,
        highlightQuery: query,
        onToggleExpanded: () => controller.toggle(group.groupKey),
      ),
      itemBuilder: (context, group, item, index) {
        final id = itemId(item);
        final tile = tileBuilder(
          context,
          item,
          isDeleted: deletedIds.contains(id),
          isQueued: queuedIds.contains(id),
          isFailed: failedIds.contains(id),
        );
        if (id != highlightId.value) return tile;
        return ScrollTargetHighlight(
          active: true,
          onComplete: () {
            if (!context.mounted) return;
            highlightId.value = null;
            forcedCompactKey.value = null;
          },
          child: tile,
        );
      },
    );
  }
}

class _GroupHeader<T> extends HookConsumerWidget {
  final VideoGroup<T> group;
  final String Function(T item) itemId;
  final CueController compactMotion;
  final bool isExpanded;
  final ValueNotifier<bool> selectionMode;
  final Set<String> ineligibleIds;
  final String highlightQuery;
  final VoidCallback onToggleExpanded;

  const _GroupHeader({
    super.key,
    required this.group,
    required this.itemId,
    required this.compactMotion,
    required this.isExpanded,
    required this.selectionMode,
    required this.ineligibleIds,
    required this.highlightQuery,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupItemIds = useMemoized(() => group.items.map(itemId).toSet(), [
      group,
    ]);
    final selection = ref.watch(
      deletionSetProvider.select((selected) {
        var hits = 0;
        for (final id in groupItemIds) {
          if (selected.contains(id)) hits++;
        }
        return (
          all: groupItemIds.isNotEmpty && hits == groupItemIds.length,
          any: hits > 0,
        );
      }),
    );

    return VideoGroupHeader(
      group: group,
      compactMotion: compactMotion,
      isExpanded: isExpanded,
      selectionMode: selectionMode.value,
      allSelected: selection.all,
      someSelected: selection.any && !selection.all,
      highlightQuery: highlightQuery,
      onToggleGroupSelection: () =>
          toggleGroupSelection(ref, groupItemIds, ineligibleIds),
      onLongPress: () {
        selectionMode.value = true;
        toggleGroupSelection(ref, groupItemIds, ineligibleIds);
      },
      onToggleExpanded: onToggleExpanded,
    );
  }
}
