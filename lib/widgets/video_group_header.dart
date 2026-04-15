import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_sticky_collapsable_panel/sliver_sticky_collapsable_panel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/video.dart';
import '../models/video_group.dart';
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

  const VideoGroupHeader({
    super.key,
    required this.group,
    required this.status,
    required this.selectionMode,
    required this.allSelected,
    required this.someSelected,
    required this.onToggleGroupSelection,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final videoMap = ref.watch(videoMetadataProvider).value ?? {};
    final Video? video =
        group.groupType == GroupType.video ? videoMap[group.groupKey] : null;

    final title = _resolveTitle(video);
    final subtitle =
        '${group.items.length} ${group.items.length == 1 ? 'item' : 'items'}';
    final thumbnailUrl = video?.thumbnailUrl;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: null, // handled by SliverStickyCollapsablePanel
        child: (status.isPinned || !status.isExpanded)
            ? _buildCompact(theme, title, subtitle, thumbnailUrl)
            : _buildLarge(theme, title, subtitle, thumbnailUrl),
      ),
    );
  }

  Widget _buildLarge(
    ThemeData theme,
    String title,
    String subtitle,
    String? thumbnailUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Checkbox(
                value: allSelected ? true : (someSelected ? null : false),
                tristate: true,
                onChanged: (_) => onToggleGroupSelection(),
              ),
            ),
          _buildThumbnail(thumbnailUrl, theme, width: 160, height: 90),
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
    );
  }

  Widget _buildCompact(
    ThemeData theme,
    String title,
    String subtitle,
    String? thumbnailUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Checkbox(
                value: allSelected ? true : (someSelected ? null : false),
                tristate: true,
                onChanged: (_) => onToggleGroupSelection(),
              ),
            ),
          _buildThumbnail(thumbnailUrl, theme, width: 48, height: 27),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                HighlightedText(
                  title,
                  query: highlightQuery,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
              final uri = Uri.https(
                'www.youtube.com',
                '/watch',
                {'v': group.groupKey},
              );
              launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        Icon(
          status.isExpanded ? Icons.expand_less : Icons.expand_more,
          color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildThumbnail(
    String? thumbnailUrl,
    ThemeData theme, {
    required double width,
    required double height,
  }) {
    final radius = width >= 120 ? 8.0 : 4.0;

    if (thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          thumbnailUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _placeholderIcon(theme, width: width, height: height),
        ),
      );
    }

    return _placeholderIcon(theme, width: width, height: height);
  }

  Widget _placeholderIcon(
    ThemeData theme, {
    required double width,
    required double height,
  }) {
    final icon = switch (group.groupType) {
      GroupType.video => Icons.videocam_outlined,
      GroupType.post => Icons.article_outlined,
      GroupType.orphaned => Icons.help_outline,
    };

    final radius = width >= 120 ? 8.0 : 4.0;
    final iconSize = height * 0.5;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
