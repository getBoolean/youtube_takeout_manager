import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';
import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import '../application/viewed_takeout_providers.dart';
import 'switch_takeout_dialog.dart';
import 'takeout_switcher.dart';

/// The takeout channel being viewed, with a way to switch takeouts.
class TakeoutAccountSection extends ConsumerWidget {
  const TakeoutAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewed = ref.watch(viewedChannelProvider);
    final channels = ref.watch(takeoutChannelsProvider);
    final tiny = isTinyWidth(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Takeout', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (viewed == null)
          Text('No takeout imported', style: theme.textTheme.bodyMedium)
        else ...[
          ChannelIdentity(channelId: viewed.channelId, title: viewed.title),
          if (channels.length > 1) ...[
            const SizedBox(height: 4),
            Text(
              '${channels.indexOf(viewed) + 1} of ${channels.length} channels '
              'in this takeout',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => showSwitchTakeoutDialog(context),
              icon: tiny ? null : const Icon(Icons.swap_horiz),
              label: const Text('Switch takeout', textAlign: TextAlign.center),
            ),
            if (channels.length > 1)
              OutlinedButton.icon(
                onPressed: () => changeChannel(context, ref),
                icon: tiny ? null : const Icon(Icons.account_circle_outlined),
                label: const Text(
                  'Change channel',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
