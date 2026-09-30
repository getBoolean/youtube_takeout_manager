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
          'Video titles, the lengths and shapes of watched videos, and '
          'channel thumbnails loaded from YouTube are kept on this device.',
      icon: Icons.cleaning_services_outlined,
      actionLabel: 'Clear cache',
      question:
          "Clear cached video details, watched videos' lengths and shapes, "
          "channel thumbnails and not-found IDs? They're fetched from the "
          'YouTube API again on next use.',
      confirmLabel: 'Clear',
      done: 'Cache cleared.',
      failed: "Couldn't clear the cache",
      onConfirm: () => ref.read(deviceCacheClearerProvider.notifier).clear(),
    );
  }
}
