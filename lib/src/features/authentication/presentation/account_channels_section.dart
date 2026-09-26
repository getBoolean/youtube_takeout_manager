import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/label_badge.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/channel_picker_dialog.dart';

/// A Google account's channels: tap one to view it, and sign each in or out
/// on its own row, since each channel needs its own sign-in.
class AccountChannelsSection extends StatelessWidget {
  final List<TakeoutChannel> channels;
  final String? viewedChannelId;
  final Set<String> signedInChannelIds;

  /// Whether signing in can be offered, i.e. sign-in is configured.
  final bool signInEnabled;
  final ValueChanged<String> onView;
  final ValueChanged<String> onSignIn;
  final ValueChanged<String> onSignOut;

  const AccountChannelsSection({
    super.key,
    required this.channels,
    required this.viewedChannelId,
    required this.signedInChannelIds,
    required this.signInEnabled,
    required this.onView,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Channels', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final channel in channels)
          _ChannelRow(
            channel: channel,
            viewing: channel.channelId == viewedChannelId,
            signedIn: signedInChannelIds.contains(channel.channelId),
            signInEnabled: signInEnabled,
            onView: () => onView(channel.channelId),
            onSignIn: () => onSignIn(channel.channelId),
            onSignOut: () => onSignOut(channel.channelId),
          ),
      ],
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final TakeoutChannel channel;
  final bool viewing;
  final bool signedIn;
  final bool signInEnabled;
  final VoidCallback onView;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const _ChannelRow({
    required this.channel,
    required this.viewing,
    required this.signedIn,
    required this.signInEnabled,
    required this.onView,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = channel.title ?? channel.channelId;
    // The tiniest windows need the room for the name.
    final showAvatar = MediaQuery.sizeOf(context).width >= 200;
    return Material(
      color: viewing
          ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (showAvatar) ...[
                    ChannelAvatar(
                      name: name,
                      thumbnailUrl: channel.thumbnailUrl,
                      radius: 16,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(name, style: theme.textTheme.bodyLarge),
                            if (viewing) const LabelBadge('Viewing'),
                          ],
                        ),
                        Text(
                          describeChannelCounts(channel),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  if (signedIn) ...[
                    Text('Signed in', style: theme.textTheme.labelMedium),
                    TextButton(
                      onPressed: onSignOut,
                      child: const Text(
                        'Sign out',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else
                    TextButton(
                      onPressed: signInEnabled ? onSignIn : null,
                      child: const Text('Sign in', textAlign: TextAlign.center),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
