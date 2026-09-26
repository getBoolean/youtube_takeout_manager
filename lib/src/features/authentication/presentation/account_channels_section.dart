import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/label_badge.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeout_details.dart';
import '../domain/sign_in_notice.dart';
import 'sign_in_notice_banner.dart';

/// A Google account's channels, on a tinted panel inside its tile: tap one
/// to view it, and sign each in or out on its own row, since each channel
/// needs its own sign-in.
class AccountChannelsSection extends StatelessWidget {
  final List<TakeoutChannel> channels;
  final String? viewedChannelId;
  final Set<String> signedInChannelIds;

  /// Whether signing in can be offered, i.e. sign-in is configured.
  final bool signInEnabled;

  /// Whether the YouTube API is deleting, so channels can be neither viewed
  /// nor signed out until it stops.
  final bool deletionRunning;

  /// Why a channel didn't end up signed in, by channel ID.
  final Map<String, SignInNotice> notices;

  /// Channels some saved takeout has, which can be viewed.
  final Set<String> savedChannelIds;

  final ValueChanged<String> onView;
  final ValueChanged<String> onSignIn;
  final ValueChanged<String> onSignOut;
  final ValueChanged<String> onDismissNotice;

  /// Views the channel chosen instead when signing in, by its ID.
  final ValueChanged<String> onViewChosen;

  const AccountChannelsSection({
    super.key,
    required this.channels,
    required this.viewedChannelId,
    required this.signedInChannelIds,
    required this.signInEnabled,
    required this.onView,
    required this.onSignIn,
    required this.onSignOut,
    this.deletionRunning = false,
    this.notices = const {},
    this.savedChannelIds = const {},
    this.onDismissNotice = _ignore,
    this.onViewChosen = _ignore,
  });

  static void _ignore(String _) {}

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final channel in channels)
              _ChannelRow(
                channel: channel,
                viewing: channel.channelId == viewedChannelId,
                signedIn: signedInChannelIds.contains(channel.channelId),
                signInEnabled: signInEnabled,
                locked: deletionRunning,
                notice: notices[channel.channelId],
                canViewChosen: switch (notices[channel.channelId]) {
                  OtherChannelChosen(:final chosen) => savedChannelIds.contains(
                    chosen.channelId,
                  ),
                  _ => false,
                },
                onView: () => onView(channel.channelId),
                onSignIn: () => onSignIn(channel.channelId),
                onSignOut: () => onSignOut(channel.channelId),
                onDismissNotice: () => onDismissNotice(channel.channelId),
                onViewChosen: onViewChosen,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final TakeoutChannel channel;
  final bool viewing;
  final bool signedIn;
  final bool signInEnabled;
  final bool locked;
  final SignInNotice? notice;
  final bool canViewChosen;
  final VoidCallback onView;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onDismissNotice;
  final ValueChanged<String> onViewChosen;

  const _ChannelRow({
    required this.channel,
    required this.viewing,
    required this.signedIn,
    required this.signInEnabled,
    required this.locked,
    required this.notice,
    required this.canViewChosen,
    required this.onView,
    required this.onSignIn,
    required this.onSignOut,
    required this.onDismissNotice,
    required this.onViewChosen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = channel.title ?? channel.channelId;
    // The tiniest windows need the room for the name.
    final showAvatar = MediaQuery.sizeOf(context).width >= 200;
    final notice = this.notice;
    return Material(
      color: viewing
          ? theme.colorScheme.secondaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked || viewing ? null : onView,
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
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: signedIn
                    ? TextButton(
                        onPressed: locked ? null : onSignOut,
                        child: const Text(
                          'Sign out',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : TextButton(
                        onPressed: signInEnabled ? onSignIn : null,
                        child: const Text(
                          'Sign in',
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
              if (notice != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                  child: SignInNoticeBanner(
                    notice: notice,
                    targetChannelId: channel.channelId,
                    targetTitle: channel.title,
                    targetThumbnailUrl: channel.thumbnailUrl,
                    onViewChosen: switch (notice) {
                      OtherChannelChosen(:final chosen)
                          when canViewChosen && !locked =>
                        () => onViewChosen(chosen.channelId),
                      _ => null,
                    },
                    onDismiss: onDismissNotice,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
