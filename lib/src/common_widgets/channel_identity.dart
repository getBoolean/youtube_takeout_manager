import 'package:flutter/material.dart';

import 'breakpoints.dart';
import 'channel_avatar.dart';

/// A YouTube channel as its title, when known, over its selectable address,
/// so two channels can be told apart even with the same title.
class ChannelIdentity extends StatelessWidget {
  final String channelId;
  final String? title;

  /// What the channel is to the user, e.g. "You chose", above the title.
  final String? label;

  /// The channel's picture, shown beside it when known.
  final String? thumbnailUrl;

  const ChannelIdentity({
    super.key,
    required this.channelId,
    this.title,
    this.label,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label case final label?)
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (title case final title?)
          Text(title, style: theme.textTheme.titleSmall),
        SelectableText(
          'youtube.com/channel/$channelId',
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    // The tiniest windows need the room for the name.
    if (thumbnailUrl == null || isTinyWidth(context)) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChannelAvatar(
          name: title ?? channelId,
          thumbnailUrl: thumbnailUrl,
          radius: 16,
        ),
        const SizedBox(width: 12),
        Flexible(child: text),
      ],
    );
  }
}
