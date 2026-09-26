import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/label_badge.dart';
import 'package:youtube_takeout_manager/src/common_widgets/option_card.dart';
import '../domain/takeout_channel.dart';

/// Picks which of a takeout's [channels] to view. Returns the channel ID, or
/// null if dismissed.
class ChannelPickerDialog extends StatelessWidget {
  final List<TakeoutChannel> channels;
  final String? viewedChannelId;

  /// Channels with a saved sign-in.
  final Set<String> signedInChannelIds;

  const ChannelPickerDialog({
    super.key,
    required this.channels,
    this.viewedChannelId,
    this.signedInChannelIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      title: const Text('Choose a channel'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final channel in channels)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OptionCard(
                  icon: Icons.account_circle_outlined,
                  leading: ChannelAvatar(
                    name: channel.title ?? channel.channelId,
                    thumbnailUrl: channel.thumbnailUrl,
                    radius: 16,
                  ),
                  title: channel.title ?? channel.channelId,
                  subtitle: describeChannel(
                    channel,
                    signedIn: signedInChannelIds.contains(channel.channelId),
                  ),
                  badge: _badges(channel),
                  onTap: () => Navigator.pop(context, channel.channelId),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget? _badges(TakeoutChannel channel) {
    final viewing = channel.channelId == viewedChannelId;
    if (!channel.isMain && !viewing) return null;
    return Wrap(
      spacing: 4,
      children: [
        if (channel.isMain) const LabelBadge('Main'),
        if (viewing) const LabelBadge('Viewing'),
      ],
    );
  }
}

/// A channel's item counts, whether it's signed in, and its ID when its
/// title stands in for it, e.g. "1,234 comments · 5 live chats · Signed in
/// · UC…".
String describeChannel(TakeoutChannel channel, {required bool signedIn}) {
  final number = NumberFormat.decimalPattern();
  return [
    Intl.plural(
      channel.commentCount,
      one: '1 comment',
      other: '${number.format(channel.commentCount)} comments',
    ),
    Intl.plural(
      channel.liveChatCount,
      one: '1 live chat',
      other: '${number.format(channel.liveChatCount)} live chats',
    ),
    if (signedIn) 'Signed in',
    if (channel.title != null) channel.channelId,
  ].join(' · ');
}
