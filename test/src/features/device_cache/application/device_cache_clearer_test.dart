import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/channel_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/device_cache/application/device_cache_clearer.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

class _VideoCache implements VideoCacheRepository {
  var clears = 0;

  @override
  Future<void> clearCache() async => clears++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ChannelCache implements ChannelCacheRepository {
  var clears = 0;

  @override
  Future<Map<String, String>> loadCachedThumbnails() async =>
      clears == 0 ? {'UCold': 'https://saved/UCold'} : {};

  @override
  Future<void> clearThumbnails() async => clears++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Videos extends VideoMetadata {
  var builds = 0;

  @override
  Stream<Map<String, Video>> build() {
    builds++;
    return Stream.value(const {});
  }
}

void main() {
  test('clears the kept video details and channel pictures, and loads '
      'them again', () async {
    final videoCache = _VideoCache();
    final channelCache = _ChannelCache();
    final videos = _Videos();
    final c = ProviderContainer(
      overrides: [
        videoCacheRepositoryProvider.overrideWithValue(videoCache),
        channelCacheRepositoryProvider.overrideWithValue(channelCache),
        videoMetadataProvider.overrideWith(() => videos),
      ],
    );
    addTearDown(c.dispose);
    c.listen(videoMetadataProvider, (_, _) {});

    await c.read(deviceCacheClearerProvider.notifier).clear();
    c.read(videoMetadataProvider);

    expect(videoCache.clears, 1);
    expect(channelCache.clears, 1);
    expect(videos.builds, 2);
  });

  test('shows no channel pictures as soon as they are cleared', () async {
    final c = ProviderContainer(
      overrides: [
        videoCacheRepositoryProvider.overrideWithValue(_VideoCache()),
        channelCacheRepositoryProvider.overrideWithValue(_ChannelCache()),
        videoMetadataProvider.overrideWith(_Videos.new),
      ],
    );
    addTearDown(c.dispose);
    c.listen(channelThumbnailsProvider, (_, _) {});
    expect(await c.read(channelThumbnailsProvider.future), isNotEmpty);

    await c.read(deviceCacheClearerProvider.notifier).clear();

    final pictures = c.read(channelThumbnailsProvider);
    expect(pictures.isLoading, isFalse);
    expect(pictures.value, isEmpty);
  });
}
