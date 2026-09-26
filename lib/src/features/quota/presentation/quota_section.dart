import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/confirmed_action_section.dart';
import '../application/quota_notifier.dart';
import 'quota_status_bar.dart';

/// Today's YouTube API quota usage, and resetting the count after asking in
/// place.
class QuotaSection extends ConsumerWidget {
  const QuotaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmedActionSection(
      title: 'YouTube API quota',
      description:
          "Your daily YouTube API allowance. It's used to load video titles, "
          'look up your channel, and delete via the API. Deleting via My '
          "Activity doesn't use it.",
      body: const QuotaStatusBar(padding: EdgeInsets.zero),
      icon: Icons.restart_alt,
      actionLabel: 'Reset usage',
      question:
          'Reset the tracked quota usage to zero? Use this if the count is '
          'out of sync with your actual usage.',
      confirmLabel: 'Reset',
      done: 'Quota usage reset.',
      failed: "Couldn't reset quota usage",
      onConfirm: () => ref.read(quotaProvider.notifier).resetUsage(),
    );
  }
}
