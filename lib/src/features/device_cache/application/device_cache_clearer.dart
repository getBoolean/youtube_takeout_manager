import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/history/application/watched_video_format_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_format_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_title_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_format_cache_repository.dart';

part 'device_cache_clearer.g.dart';

/// Clears what's loaded from YouTube and kept on this device, so it's
/// fetched again. A service: nothing depends on it, so it can read any
/// provider.
@Riverpod(keepAlive: true)
class DeviceCacheClearer extends _$DeviceCacheClearer {
  @override
  void build() {}

  /// Clears the video details, the watched videos' lengths and shapes,
  /// channel pictures and not-found video IDs kept on this device.
  Future<void> clear() async {
    await ref.read(videoCacheRepositoryProvider).clearCache();
    await ref.read(videoFormatCacheRepositoryProvider).clear();
    await ref.read(channelThumbnailsProvider.notifier).clear();
    ref.read(channelThumbnailFetcherProvider.notifier).forgetMissing();

    ref.invalidate(videoMetadataProvider);
    ref.invalidate(videoFormatsProvider);
    // Fetches what was cleared again.
    ref.invalidate(videoTitleFetcherProvider);
    ref.invalidate(watchedVideoFormatFetcherProvider);
  }
}
