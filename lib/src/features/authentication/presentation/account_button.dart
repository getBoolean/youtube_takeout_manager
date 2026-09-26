import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeouts_dialog.dart';

/// App bar button that opens the Takeouts dialog: the viewed channel's
/// picture, or an outline account icon when no takeout is shown.
class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(viewedChannelProvider);
    final name = channel?.title ?? channel?.channelId;
    return IconButton(
      tooltip: name == null ? 'Account' : 'Account: $name',
      onPressed: () => showTakeoutsDialog(context),
      icon: channel == null
          ? const Icon(Icons.account_circle_outlined)
          : ChannelAvatar(
              name: name!,
              thumbnailUrl: channel.thumbnailUrl,
              radius: 16,
            ),
    );
  }
}
