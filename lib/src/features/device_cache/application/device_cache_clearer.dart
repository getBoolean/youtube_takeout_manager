import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_title_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';

part 'device_cache_clearer.g.dart';

/// Clears what's loaded from YouTube and kept on this device, so it's
/// fetched again. A service: nothing depends on it, so it can read any
/// provider.
@Riverpod(keepAlive: true)
class DeviceCacheClearer extends _$DeviceCacheClearer {
  @override
  void build() {}

  /// Clears the video details, channel pictures and not-found video IDs
  /// kept on this device.
  Future<void> clear() async {
    await ref.read(videoCacheRepositoryProvider).clearCache();
    await ref.read(channelThumbnailsProvider.notifier).clear();

    ref.invalidate(videoMetadataProvider);
    // Fetches what was cleared again.
    ref.invalidate(videoTitleFetcherProvider);
  }
}
