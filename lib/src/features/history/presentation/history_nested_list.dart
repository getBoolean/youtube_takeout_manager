import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/share_bar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_colors.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../domain/category_nests.dart';
import '../domain/channel_groups.dart';
import 'history_channel_list.dart';

/// The watched videos grouped by channel, nested under the categories
/// picked: a sticky header for each category, open at first, over its
/// channels' headers, closed at first, each over its videos. Built lazily
/// however many there are. [categories] keeps which categories are open,
/// [channels] which channels.
class HistoryNestedList extends StatelessWidget {
  final List<CategoryNest> nests;
  final StickyGroupedListController categories;
  final StickyGroupedListController channels;
  final ScrollController scrollController;

  /// The keys of the channels subscribed to.
  final Set<String> subscribedKeys;

  /// Channel pictures by channel ID.
  final Map<String, String> pictures;

  /// Highlighted in the channels' names; empty for none.
  final String query;

  /// Told the channel of each channel header as it's built.
  final ValueChanged<String?> onChannelShown;

  /// Goes under a channel's name, e.g. its tags.
  final Widget? Function(BuildContext context, HistoryChannelGroup group)?
  channelExtra;

  final Widget Function(BuildContext context, int index) entryBuilder;

  const HistoryNestedList({
    super.key,
    required this.nests,
    required this.categories,
    required this.channels,
    required this.scrollController,
    required this.subscribedKeys,
    required this.pictures,
    this.query = '',
    required this.onChannelShown,
    this.channelExtra,
    required this.entryBuilder,
  });

  /// Categories have no header state; the list needs one per header
  /// regardless.
  static const _noState = Object();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: channels,
    builder: (context, _) {
      final rows = {
        for (final nest in nests)
          nest.key: NestedRows(nest.channels, channels.isExpanded),
      };
      return StickyGroupedListView<CategoryNest, NestedRow, Object>(
        // A new list, so the list works out its rows again as channels open
        // and close.
        groups: [...nests],
        groupKey: (nest) => nest.key,
        itemsOf: (nest) => rows[nest.key]!,
        itemKey: (row) => switch (row) {
          ChannelRow(:final group) => 'channel ${group.key}',
          VideoRow(:final watchIndex) => watchIndex,
        },
        controller: categories,
        scrollController: scrollController,
        // Keeps its place while another tab is open.
        keepAlive: true,
        createHeaderState: (_, _, _) => _noState,
        updateHeaderState: (_, _, _) {},
        disposeHeaderState: (_) {},
        headerBuilder: (context, nest, _, status) => CategoryNestHeader(
          nest: nest,
          expanded: status.isExpanded,
          onTap: () => categories.toggle(nest.key),
        ),
        itemBuilder: (context, nest, row, _) => switch (row) {
          ChannelRow(:final group) => _channel(context, group),
          VideoRow(:final watchIndex) => entryBuilder(context, watchIndex),
        },
        trailing: const SliverToBoxAdapter(child: SizedBox(height: 24)),
      );
    },
  );

  Widget _channel(BuildContext context, HistoryChannelGroup group) {
    onChannelShown(group.channel?.channelId);
    return ChannelGroupHeader(
      group: group,
      expanded: channels.isExpanded(group.key),
      subscribed: subscribedKeys.contains(group.key),
      picture: pictures[group.channel?.channelId],
      query: query,
      extra: channelExtra?.call(context, group),
      onTap: group.indices.isEmpty ? null : () => channels.toggle(group.key),
    );
  }
}

/// A category's header in the nested list: its emoji and name on its
/// colour, its share of the videos shown as a bar in its colour, the
/// percent and how many videos and channels it has, and a chevron that
/// turns as it opens. Tapping it opens or closes the category. Opaque,
/// since its pinned copy is drawn over the rows.
class CategoryNestHeader extends ConsumerWidget {
  final CategoryNest nest;
  final bool expanded;
  final VoidCallback onTap;

  const CategoryNestHeader({
    super.key,
    required this.nest,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final pick = nest.pick;
    final parent = pick.parent;
    final emoji = ref.watch(categoryEmojiOfProvider)(
      parent == null ? null : CategoryPath(parent, pick.child),
    );
    final videos = formatCount(nest.videoCount, 'video');
    final channels = formatCount(nest.channelCount, 'channel');
    final animate = !MediaQuery.disableAnimationsOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: categoryTint(parent, scheme),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Semantics(
        expanded: expanded,
        button: true,
        label:
            '${pick.label}: ${(nest.share * 100).round()} percent of the '
            'videos shown, $videos, $channels',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: EdgeInsets.fromLTRB(tiny ? 8 : 16, 8, tiny ? 4 : 8, 8),
              child: Row(
                children: [
                  Text(emoji, style: theme.textTheme.titleMedium),
                  SizedBox(width: tiny ? 6 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          pick.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ShareBar(
                          share: nest.share,
                          color: categoryColor(parent, scheme.brightness),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatShare(nest.share)} · $videos · $channels',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
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
