import 'dart:math' as math;

import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' show nearEqual, nearZero;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/scroll_target_highlight.dart';
import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/selection_providers.dart';
import '../../domain/video_group.dart';
import 'header_animation_controller.dart';
import 'video_group_header.dart';

typedef VideoGroupTileBuilder =
    Widget Function(
      BuildContext context,
      Interaction item,
      InteractionStatus status,
    );

/// Groups loaded before a scroll target is resolved; all but the target's
/// group are collapsed so the jump lands on a stable layout.
const _targetSiblingWindow = 15;

/// A channel's comments or live chats grouped by video, with sticky headers
/// that morph from large to compact as they pin.
class VideoGroupListView extends HookConsumerWidget {
  final List<VideoGroup<Interaction>> groups;
  final VideoGroupTileBuilder tileBuilder;
  final InteractionStatuses statuses;

  /// Whose selection mode the headers follow.
  final String channelId;
  final ScrollController scrollController;
  final String? initialScrollTarget;

  const VideoGroupListView({
    super.key,
    required this.groups,
    required this.tileBuilder,
    required this.statuses,
    required this.channelId,
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
        if (groups[g].items.any((item) => item.id == id)) {
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

    useValueChanged<Object?, void>(
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
    bool isCompact(VideoGroup<Interaction> group, StickyHeaderStatus status) {
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

    final ineligibleIds = statuses.unselectableIds;

    return StickyGroupedListView<
      VideoGroup<Interaction>,
      Interaction,
      CueController
    >(
      groups: groups,
      groupKey: (group) => group.groupKey,
      itemsOf: (group) => group.items,
      itemKey: (item) => item.id,
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
      headerBuilder: (context, group, motion, status) => _GroupHeader(
        group: group,
        compactMotion: motion,
        isExpanded: status.isExpanded,
        channelId: channelId,
        ineligibleIds: ineligibleIds,
        highlightQuery: query,
        onToggleExpanded: () => controller.toggle(group.groupKey),
      ),
      itemBuilder: (context, group, item, index) {
        final id = item.id;
        final tile = tileBuilder(context, item, statuses.of(id));
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

class _GroupHeader extends HookConsumerWidget {
  final VideoGroup<Interaction> group;
  final CueController compactMotion;
  final bool isExpanded;
  final String channelId;
  final Set<String> ineligibleIds;
  final String highlightQuery;
  final VoidCallback onToggleExpanded;

  const _GroupHeader({
    required this.group,
    required this.compactMotion,
    required this.isExpanded,
    required this.channelId,
    required this.ineligibleIds,
    required this.highlightQuery,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupItemIds = useMemoized(
      () => group.items.map((i) => i.id).toSet(),
      [group],
    );
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

    final selectionMode = selectionModeProvider(channelId: channelId);
    void toggleGroup() => ref
        .read(deletionSetProvider.notifier)
        .toggleGroup(groupItemIds, ineligibleIds: ineligibleIds);

    return VideoGroupHeader(
      group: group,
      compactMotion: compactMotion,
      isExpanded: isExpanded,
      selectionMode: ref.watch(selectionMode),
      allSelected: selection.all,
      someSelected: selection.any && !selection.all,
      highlightQuery: highlightQuery,
      onToggleGroupSelection: toggleGroup,
      onLongPress: () {
        ref.read(selectionMode.notifier).enter();
        toggleGroup();
      },
      onToggleExpanded: onToggleExpanded,
    );
  }
}
