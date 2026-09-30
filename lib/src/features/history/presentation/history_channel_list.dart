import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../domain/channel_groups.dart';

/// The watched videos under a sticky header for each channel, built lazily
/// however many there are. Entries are indices into the history's watched
/// videos.
class HistoryChannelList extends StatelessWidget {
  final ChannelGroups groups;

  /// Each watched video's channel, as the loaded history has it.
  final Int32List watchChannelIndex;
  final StickyGroupedListController controller;
  final ScrollController scrollController;

  /// The keys of the channels subscribed to.
  final Set<String> subscribedKeys;

  /// Channel pictures by channel ID.
  final Map<String, String> pictures;

  /// Highlighted in the channels' names; empty for none.
  final String query;

  /// Told the channel of each header as it's built.
  final ValueChanged<String?> onChannelShown;

  /// Goes under a channel's name, e.g. its category.
  final Widget? Function(BuildContext context, HistoryChannelGroup group)?
  headerExtra;

  final Widget Function(BuildContext context, int index) entryBuilder;

  const HistoryChannelList({
    super.key,
    required this.groups,
    required this.watchChannelIndex,
    required this.controller,
    required this.scrollController,
    required this.subscribedKeys,
    required this.pictures,
    this.query = '',
    required this.onChannelShown,
    this.headerExtra,
    required this.entryBuilder,
  });

  /// Channels have no header state; the list needs one per header regardless.
  static const _noState = Object();

  @override
  Widget build(BuildContext context) {
    return StickyGroupedListView<HistoryChannelGroup, int, Object>(
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
      headerBuilder: (context, group, _, status) {
        onChannelShown(group.channel?.channelId);
        return ChannelGroupHeader(
          group: group,
          expanded: status.isExpanded,
          subscribed: subscribedKeys.contains(group.key),
          picture: pictures[group.channel?.channelId],
          query: query,
          extra: headerExtra?.call(context, group),
          onTap: group.indices.isEmpty
              ? null
              : () => controller.toggle(group.key),
        );
      },
      itemBuilder: (context, group, index, _) => entryBuilder(context, index),
      trailing: const SliverToBoxAdapter(child: SizedBox(height: 24)),
    );
  }
}

/// A channel's header: its picture and name, how many of its videos were
/// watched and whether it's subscribed to, anything [extra] (such as its
/// category), and a chevron that turns as it opens. Tapping it opens or
/// closes the channel; a channel never watched has nothing to open. Opaque,
/// since its pinned copy is drawn over the rows.
class ChannelGroupHeader extends StatelessWidget {
  final HistoryChannelGroup group;
  final bool expanded;
  final bool subscribed;
  final String? picture;
  final String query;
  final Widget? extra;
  final VoidCallback? onTap;

  const ChannelGroupHeader({
    super.key,
    required this.group,
    required this.expanded,
    required this.subscribed,
    this.picture,
    this.query = '',
    this.extra,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final channel = group.channel;
    final watched = group.indices.length;
    final detail = [
      watched == 0 ? 'Never watched' : formatCount(watched, 'video'),
      if (subscribed) 'Subscribed',
    ].join(' · ');
    final name = channel?.title ?? 'Videos without a channel';
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
                    channel == null
                        ? CircleAvatar(
                            radius: 20,
                            backgroundColor: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.videocam_off_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          )
                        : ChannelAvatar(
                            name: channel.title,
                            thumbnailUrl: picture,
                            radius: 20,
                          ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HighlightedText(
                          name,
                          query: channel == null ? '' : query,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (extra case final extra?) ...[
                          const SizedBox(height: 4),
                          extra,
                        ],
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
