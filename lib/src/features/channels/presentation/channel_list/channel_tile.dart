import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import '../../domain/channel.dart';

class ChannelTile extends StatelessWidget {
  final Channel channel;
  final String? highlightQuery;
  final VoidCallback onTap;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
    this.highlightQuery,
  });

  /// Below this width the counts are left out, so the trailing widget
  /// always fits beside the title.
  static const _countsMinWidth = 300.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildTile(
        context,
        showCounts: constraints.maxWidth >= _countsMinWidth,
      ),
    );
  }

  Widget _buildTile(BuildContext context, {required bool showCounts}) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: channel.thumbnailUrl != null
            ? ClipOval(
                child: Image.network(
                  channel.thumbnailUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                ),
              )
            : Text(
                (channel.channelTitle ?? '?')[0].toUpperCase(),
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
      ),
      title: HighlightedText(
        channel.channelTitle ?? 'Unknown Channel',
        query: highlightQuery,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: channel.channelTitle == null
          ? HighlightedText(
              channel.channelId,
              query: highlightQuery,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCounts) ...[
            if (channel.commentCount > 0)
              _Badge(
                icon: Icons.comment_outlined,
                count: channel.commentCount,
                color: theme.colorScheme.primary,
              ),
            if (channel.commentCount > 0 && channel.liveChatCount > 0)
              const SizedBox(width: 8),
            if (channel.liveChatCount > 0)
              _Badge(
                icon: Icons.chat_bubble_outline,
                count: channel.liveChatCount,
                color: theme.colorScheme.secondary,
              ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _Badge({required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
