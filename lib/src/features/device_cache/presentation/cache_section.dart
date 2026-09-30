import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/confirmed_action_section.dart';
import '../application/device_cache_clearer.dart';

/// What's loaded from YouTube and kept on this device, and clearing it after
/// asking in place.
class CacheSection extends ConsumerWidget {
  const CacheSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConfirmedActionSection(
      title: 'Cache',
      description:
          'Channel pictures and video thumbnails are kept on this device, '
          'so they show at once and offline.',
      icon: Icons.cleaning_services_outlined,
      actionLabel: 'Clear cache',
      question:
          'Clear the pictures and thumbnails kept on this device? They '
          "download again as they're shown. Video details, channel topics "
          'and categories are kept.',
      confirmLabel: 'Clear',
      done: 'Cache cleared.',
      failed: "Couldn't clear the cache",
      onConfirm: () => ref.read(deviceCacheClearerProvider.notifier).clear(),
    );
  }
}
