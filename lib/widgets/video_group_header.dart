import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sliver_sticky_collapsable_panel/sliver_sticky_collapsable_panel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/video.dart';
import '../models/video_group.dart';
import '../providers/header_animation_providers.dart';
import '../providers/video_providers.dart';
import 'highlighted_text.dart';

class VideoGroupHeader extends ConsumerWidget {
  final VideoGroup group;
  final SliverStickyCollapsablePanelStatus status;
  final bool selectionMode;
  final bool allSelected;
  final bool someSelected;
  final String? highlightQuery;
  final VoidCallback onToggleGroupSelection;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleExpanded;

  /// When true the header renders in its compact layout regardless of
  /// scroll/pin state, and the Cue transition is disabled. Used during
  /// scroll-to-target so the target group's header has a stable, known
  /// height from the first frame — the scroll animation can land on a
  /// single precomputed offset without chasing a layout that shrinks when
  /// the header pins mid-scroll.
  final bool forceCompact;

  const VideoGroupHeader({
    super.key,
    required this.group,
    required this.status,
    required this.selectionMode,
    required this.allSelected,
    required this.someSelected,
    required this.onToggleGroupSelection,
    this.highlightQuery,
    this.onLongPress,
    this.onToggleExpanded,
    this.forceCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final videoMap = ref.watch(videoMetadataProvider).value ?? {};
    final Video? video = group.groupType == GroupType.video
        ? videoMap[group.groupKey]
        : null;

    final title = _resolveTitle(video);
    final subtitle = Intl.plural(
      group.items.length,
      one: '1 item',
      other: '${group.items.length} items',
    );
    final thumbnailUrl = video?.thumbnailUrl;
    // scrollPercentage hits 1.0 once the header is fully scrolled past the top.
    // Include it so groups above the viewport stay compact instead of trying to
    // animate back to large (which would grow their sliver extent and shake the
    // whole list).
    final isCompact =
        forceCompact ||
        status.isPinned ||
        !status.isExpanded ||
        status.scrollPercentage >= 1.0;
    final suppressAnimation =
        forceCompact || ref.watch(suppressHeaderAnimationProvider);
    const CueMotion springMotion = Spring.smooth();
    final CueMotion motion = suppressAnimation ? CueMotion.none : springMotion;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: selectionMode ? onToggleGroupSelection : onToggleExpanded,
        onLongPress: onLongPress,
        child: Cue.onToggle(
          toggled: isCompact,
          motion: motion,
          reverseMotion: motion,
          child: Actor(
            acts: const [
              Act.padding(
                from: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                to: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Cue.onToggle(
                  toggled: selectionMode,
                  motion: motion,
                  reverseMotion: motion,
                  acts: const [ClipAct.width(), OpacityAct.fadeIn()],
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: Checkbox(
                      value: allSelected ? true : (someSelected ? null : false),
                      tristate: true,
                      onChanged: (_) => onToggleGroupSelection(),
                    ),
                  ),
                ),
                Actor(
                  acts: const [
                    Act.sizedBox(
                      width: AnimatableValue.tween(160, 78),
                      height: AnimatableValue.tween(90, 44),
                      alignment: Alignment.centerLeft,
                    ),
                  ],
                  child: _buildThumbnail(thumbnailUrl, theme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HighlightedText(
                        title,
                        query: highlightQuery,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTrailingActions(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingActions(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (group.groupType == GroupType.video)
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 20),
            tooltip: 'Open on YouTube',
            onPressed: () {
              final uri = Uri.https('www.youtube.com', '/watch', {
                'v': group.groupKey,
              });
              launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        IconButton(
          icon: Icon(
            status.isExpanded ? Icons.expand_less : Icons.expand_more,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: status.isExpanded ? 'Collapse' : 'Expand',
          onPressed: onToggleExpanded,
        ),
      ],
    );
  }

  String _resolveTitle(Video? video) {
    switch (group.groupType) {
      case GroupType.video:
        return video?.title ?? 'Video: ${group.groupKey}';
      case GroupType.post:
        final postId = group.groupKey.replaceFirst('post:', '');
        return 'Community Post: $postId';
      case GroupType.orphaned:
        return 'Other';
    }
  }

  Widget _buildThumbnail(String? thumbnailUrl, ThemeData theme) {
    if (thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholderIcon(theme),
        ),
      );
    }

    return _placeholderIcon(theme);
  }

  Widget _placeholderIcon(ThemeData theme) {
    final icon = switch (group.groupType) {
      GroupType.video => Icons.videocam_outlined,
      GroupType.post => Icons.article_outlined,
      GroupType.orphaned => Icons.help_outline,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
