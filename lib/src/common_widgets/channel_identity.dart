import 'package:flutter/material.dart';

/// A YouTube channel as its title, when known, over its selectable address,
/// so two channels can be told apart even with the same title.
class ChannelIdentity extends StatelessWidget {
  final String channelId;
  final String? title;

  /// What the channel is to the user, e.g. "You chose", above the title.
  final String? label;

  const ChannelIdentity({
    super.key,
    required this.channelId,
    this.title,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
  }
}
