import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';

/// Heads the queue items posted on [channelId], or on an unknown channel
/// when it's null, with how many there are.
class QueueChannelGroupHeader extends ConsumerWidget {
  final String? channelId;
  final int count;

  const QueueChannelGroupHeader({
    super.key,
    required this.channelId,
    required this.count,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final channel = ref.watch(
      channelsProvider.select(
        (channels) =>
            channels.where((c) => c.channelId == channelId).firstOrNull,
      ),
    );
    final name = channel?.channelTitle ?? 'Unknown channel';
    final thumbnailUrl = channel?.thumbnailUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          ChannelAvatar(name: name, thumbnailUrl: thumbnailUrl, radius: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.labelLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
