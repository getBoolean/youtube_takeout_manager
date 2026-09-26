import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import '../domain/sign_in_profile.dart';

/// The Google account a takeout is from: named by one of its channels'
/// sign-ins, else by its main channel until one signs in.
class GoogleAccountHeader extends StatelessWidget {
  /// The sign-in naming the account (see `accountProfileFor`).
  final SignInProfile? profile;

  /// The takeout's main channel, or null without a takeout.
  final TakeoutChannel? mainChannel;
  final DateTime? exportedAt;

  const GoogleAccountHeader({
    super.key,
    this.profile,
    this.mainChannel,
    this.exportedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final main = mainChannel;
    final profile = this.profile;
    if (main == null && profile == null) {
      return Text('No takeout imported', style: theme.textTheme.titleMedium);
    }
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final String name;
    final List<String> details;
    final String? picture;
    if (profile != null) {
      name = profile.displayName ?? profile.email ?? 'Google account';
      details = [if (profile.displayName != null) ?profile.email];
      picture = profile.photoUrl;
    } else {
      name = main!.title ?? main.channelId;
      details = const ['Not signed in with Google'];
      picture = main.thumbnailUrl;
    }
    final exported = exportedAt;

    // A narrow window gets a smaller picture, and the tiniest none, so the
    // name has room.
    final windowWidth = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        if (!isTinyWidth(context)) ...[
          ChannelAvatar(
            name: name,
            thumbnailUrl: picture,
            radius: windowWidth < 320 ? 20 : 28,
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.titleMedium),
              for (final detail in details) Text(detail, style: secondary),
              if (exported != null)
                Text(
                  'Takeout exported '
                  '${DateFormat.yMMMd().format(exported.toLocal())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
