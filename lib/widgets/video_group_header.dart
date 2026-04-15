import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_sticky_collapsable_panel/sliver_sticky_collapsable_panel.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/video.dart';
import '../models/video_group.dart';
import '../providers/video_providers.dart';

class VideoGroupHeader extends ConsumerWidget {
  final VideoGroup group;
  final SliverStickyCollapsablePanelStatus status;
  final bool selectionMode;
  final bool allSelected;
  final bool someSelected;
  final VoidCallback onToggleGroupSelection;

  const VideoGroupHeader({
    super.key,
    required this.group,
    required this.status,
    required this.selectionMode,
    required this.allSelected,
    required this.someSelected,
    required this.onToggleGroupSelection,
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
        child: Padding(
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
              _buildThumbnail(thumbnailUrl, theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
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
                status.isExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
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
    const width = 48.0;
    const height = 27.0; // 16:9 aspect ratio

    if (thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          thumbnailUrl,
          width: width,
          height: height,
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

    return Container(
      width: 48,
      height: 27,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
