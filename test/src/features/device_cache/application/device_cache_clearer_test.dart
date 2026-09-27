import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/channel_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/device_cache/application/device_cache_clearer.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

/// Video details kept on the device, in memory.
class _VideoCache implements VideoCacheRepository {
  var videos = <String, Video>{
    'v1': const Video(videoId: 'v1', channelId: 'UCold', title: 'Old'),
  };

  @override
  Future<Map<String, Video>> loadCachedVideos() async => videos;

  @override
  Future<void> clearCache() async => videos = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Channel pictures kept on the device, in memory.
class _ChannelCache implements ChannelCacheRepository {
  var thumbnails = <String, String>{'UCold': 'https://saved/UCold'};

  @override
  Future<Map<String, String>> loadCachedThumbnails() async => thumbnails;

  @override
  Future<void> clearThumbnails() async => thumbnails = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _VideoCache videoCache;
  late _ChannelCache channelCache;

  ProviderContainer container() {
    videoCache = _VideoCache();
    channelCache = _ChannelCache();
    final c = ProviderContainer(
      overrides: [
        videoCacheRepositoryProvider.overrideWithValue(videoCache),
        channelCacheRepositoryProvider.overrideWithValue(channelCache),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('clears the kept video details and shows none once they load '
      'again', () async {
    final c = container();
    c.listen(videoMetadataProvider, (_, _) {});
    expect(await c.read(videoMetadataProvider.future), isNotEmpty);

    await c.read(deviceCacheClearerProvider.notifier).clear();

    expect(videoCache.videos, isEmpty);
    expect(await c.read(videoMetadataProvider.future), isEmpty);
  });

  test('shows no channel pictures as soon as they are cleared', () async {
    final c = container();
    c.listen(channelThumbnailsProvider, (_, _) {});
    expect(await c.read(channelThumbnailsProvider.future), isNotEmpty);

    await c.read(deviceCacheClearerProvider.notifier).clear();

    expect(channelCache.thumbnails, isEmpty);
    final pictures = c.read(channelThumbnailsProvider);
    expect(pictures.isLoading, isFalse);
    expect(pictures.value, isEmpty);
  });
}
