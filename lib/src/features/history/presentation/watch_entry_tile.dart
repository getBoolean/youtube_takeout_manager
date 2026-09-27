import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_meta_line.dart';
import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/common_widgets/label_badge.dart';
import 'package:youtube_takeout_manager/src/common_widgets/video_thumbnail.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/watch_entry.dart';
import 'removed_badge.dart';

/// One watched video, post or playable: its thumbnail, title, channel and
/// time of day, with what's special about it as badges.
class WatchEntryTile extends StatelessWidget {
  final WatchEntry watch;

  /// Highlighted in the title; empty for none.
  final String query;
  final VoidCallback onTap;

  const WatchEntryTile({
    super.key,
    required this.watch,
    this.query = '',
    required this.onTap,
  });

  // Narrow windows get a smaller thumbnail, then none, so the title keeps
  // its room.
  static const _fullThumbnailMinWidth = 400.0;
  static const _thumbnailMinWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoId = watch.videoId;
    final removedAt = watch.removedAt;
    final badges = [
      if (watch.music) 'Music',
      switch (watch.kind) {
        WatchKind.post => 'Post',
        WatchKind.playable => 'Playable',
        WatchKind.video => null,
      },
    ].nonNulls;

    return InkWell(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final thumbnail = width >= _fullThumbnailMinWidth
              ? const Size(120, 68)
              : width >= _thumbnailMinWidth
              ? const Size(80, 45)
              : null;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (thumbnail != null) ...[
                  SizedBox.fromSize(
                    size: thumbnail,
                    child: VideoThumbnail(
                      url: videoId == null
                          ? null
                          : 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg',
                      placeholderIcon: switch (watch.kind) {
                        WatchKind.video => Icons.videocam_outlined,
                        WatchKind.post => Icons.article_outlined,
                        WatchKind.playable => Icons.sports_esports_outlined,
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HighlightedText(
                        // A removed or private video is only known by its
                        // link.
                        watch.title ?? watch.url,
                        query: query,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ChannelMetaLine(
                        channelName: watch.channelTitle,
                        detail: formatTime(watch.time),
                      ),
                      if (badges.isNotEmpty || removedAt != null) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final badge in badges) LabelBadge(badge),
                            if (removedAt != null)
                              RemovedBadge(removedAt: removedAt),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
