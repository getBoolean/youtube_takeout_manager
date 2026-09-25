import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/common_widgets/image_url_menu.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';
import '../../domain/video_group.dart';

class VideoGroupHeader extends ConsumerWidget {
  final VideoGroup group;

  /// Drives the large (0) to compact (1) morph. Owned by the list and shared
  /// with the group's pinned header copy.
  final CueController compactMotion;
  final bool isExpanded;
  final bool selectionMode;
  final bool allSelected;
  final bool someSelected;
  final String? highlightQuery;
  final VoidCallback onToggleGroupSelection;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleExpanded;

  const VideoGroupHeader({
    super.key,
    required this.group,
    required this.compactMotion,
    required this.isExpanded,
    required this.selectionMode,
    required this.allSelected,
    required this.someSelected,
    required this.onToggleGroupSelection,
    this.highlightQuery,
    this.onLongPress,
    this.onToggleExpanded,
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

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: selectionMode ? onToggleGroupSelection : onToggleExpanded,
        onLongPress: onLongPress,
        // Narrow windows get a smaller thumbnail, then none, then no open
        // button, so the row always fits.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final thumbnailActs = width >= _fullThumbnailMinWidth
                ? _fullThumbnailActs
                : width >= _thumbnailMinWidth
                ? _smallThumbnailActs
                : null;
            return Cue(
              controller: compactMotion,
              child: Actor(
                acts: thumbnailActs != null ? _paddingActs : _narrowPaddingActs,
                child: _buildRow(
                  theme,
                  title: title,
                  subtitle: subtitle,
                  thumbnailUrl: thumbnailUrl,
                  thumbnailActs: thumbnailActs,
                  showOpenButton: width >= _openButtonMinWidth,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static const _fullThumbnailMinWidth = 400.0;
  static const _thumbnailMinWidth = 280.0;
  static const _openButtonMinWidth = 200.0;

  static const _paddingActs = [
    Act.padding(
      from: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      to: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ];
  static const _narrowPaddingActs = [
    Act.padding(
      from: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      to: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
  ];
  static const _fullThumbnailActs = [
    Act.sizedBox(
      width: AnimatableValue.tween(160, 78),
      height: AnimatableValue.tween(90, 44),
      alignment: Alignment.centerLeft,
    ),
  ];
  static const _smallThumbnailActs = [
    Act.sizedBox(
      width: AnimatableValue.tween(80, 56),
      height: AnimatableValue.tween(45, 32),
      alignment: Alignment.centerLeft,
    ),
  ];

  Widget _buildRow(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required String? thumbnailUrl,
    required List<Act>? thumbnailActs,
    required bool showOpenButton,
  }) {
    const CueMotion springMotion = Spring.smooth();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Cue.onToggle(
          toggled: selectionMode,
          motion: springMotion,
          reverseMotion: springMotion,
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
        if (thumbnailActs != null) ...[
          Actor(
            acts: thumbnailActs,
            child: _buildThumbnail(thumbnailUrl, theme),
          ),
          const SizedBox(width: 12),
        ],
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
        _buildTrailingActions(theme, showOpenButton: showOpenButton),
      ],
    );
  }

  Widget _buildTrailingActions(
    ThemeData theme, {
    required bool showOpenButton,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showOpenButton && group.groupType == GroupType.video)
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
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: isExpanded ? 'Collapse' : 'Expand',
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
      // Right-click only: a long press on the header starts selection.
      return ImageUrlMenu(
        url: thumbnailUrl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholderIcon(theme),
          ),
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
