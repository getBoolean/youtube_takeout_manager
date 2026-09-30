import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/share_bar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../domain/category_groups.dart';
import '../domain/channel_groups.dart';

/// The watched videos under a sticky header for each category, built
/// lazily however many there are. Entries are indices into the history's
/// watched videos.
class HistoryCategoryList extends StatelessWidget {
  final CategoryGroups groups;

  /// Each watched video's channel, as the loaded history has it.
  final Int32List watchChannelIndex;
  final StickyGroupedListController controller;
  final ScrollController scrollController;
  final Widget Function(BuildContext context, int index) entryBuilder;

  const HistoryCategoryList({
    super.key,
    required this.groups,
    required this.watchChannelIndex,
    required this.controller,
    required this.scrollController,
    required this.entryBuilder,
  });

  /// Categories have no header state; the list needs one per header
  /// regardless.
  static const _noState = Object();

  @override
  Widget build(BuildContext context) {
    return StickyGroupedListView<HistoryCategoryGroup, int, Object>(
      groups: groups.groups,
      groupKey: (group) => group.key,
      itemsOf: (group) => group.indices,
      itemKey: (index) => index,
      locateItem: (key) =>
          key is int ? groups.locate(key, watchChannelIndex) : null,
      controller: controller,
      scrollController: scrollController,
      // Keeps its place while another tab is open.
      keepAlive: true,
      createHeaderState: (_, _, _) => _noState,
      updateHeaderState: (_, _, _) {},
      disposeHeaderState: (_) {},
      headerBuilder: (context, group, _, status) => CategoryGroupHeader(
        group: group,
        expanded: status.isExpanded,
        onTap: group.indices.isEmpty
            ? null
            : () => controller.toggle(group.key),
      ),
      itemBuilder: (context, group, index, _) => entryBuilder(context, index),
      trailing: const SliverToBoxAdapter(child: SizedBox(height: 24)),
    );
  }
}

/// A category's header: its name, its share of the watched videos as a bar
/// and a percent, how many videos and channels it has, and a chevron that
/// turns as it opens. Tapping it opens or closes the category; one of only
/// channels never watched has nothing to open. Opaque, since its pinned
/// copy is drawn over the rows.
class CategoryGroupHeader extends StatelessWidget {
  final HistoryCategoryGroup group;
  final bool expanded;
  final VoidCallback? onTap;

  const CategoryGroupHeader({
    super.key,
    required this.group,
    required this.expanded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final noChannel = group.key == noChannelGroupKey;
    final name =
        group.path?.label ??
        (noChannel ? 'Videos without a channel' : 'Uncategorized');
    final videos = formatCount(group.indices.length, 'video');
    final detail = noChannel
        ? videos
        : [
            formatShare(group.share),
            videos,
            formatCount(group.channelCount, 'channel'),
          ].join(' · ');
    final animate = !MediaQuery.disableAnimationsOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Semantics(
        expanded: onTap == null ? null : expanded,
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: EdgeInsets.fromLTRB(tiny ? 8 : 16, 8, tiny ? 4 : 8, 8),
              child: Row(
                children: [
                  if (!tiny) ...[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: group.path == null
                          ? scheme.surfaceContainerHighest
                          : scheme.secondaryContainer,
                      child: Icon(
                        noChannel
                            ? Icons.videocam_off_outlined
                            : group.path == null
                            ? Icons.help_outline
                            : Icons.category_outlined,
                        color: group.path == null
                            ? scheme.onSurfaceVariant
                            : scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!noChannel) ...[
                          const SizedBox(height: 6),
                          ShareBar(share: group.share),
                        ],
                        const SizedBox(height: 4),
                        Semantics(
                          label: noChannel
                              ? null
                              : '${(group.share * 100).round()} percent of '
                                    'the watched videos, $videos, '
                                    '${formatCount(group.channelCount, 'channel')}',
                          child: ExcludeSemantics(
                            excluding: !noChannel,
                            child: Text(
                              detail,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: animate
                          ? const Duration(milliseconds: 200)
                          : Duration.zero,
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
