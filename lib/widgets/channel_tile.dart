import 'package:flutter/material.dart';

import '../models/channel.dart';

class ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                style:
                    TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
      ),
      title: Text(
        channel.channelTitle ?? 'Unknown Channel',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: channel.channelTitle == null
          ? Text(
              channel.channelId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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

  const _Badge({
    required this.icon,
    required this.count,
    required this.color,
  });

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
