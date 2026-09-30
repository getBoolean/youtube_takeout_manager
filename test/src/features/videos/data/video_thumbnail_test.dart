import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/youtube/v3.dart' as yt;

import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/youtube_video_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';

const _base = 'https://i.ytimg.com/vi/abc';

void main() {
  test('prefers the medium thumbnail', () {
    yt.Thumbnail thumb(String name) => yt.Thumbnail(url: '$_base/$name');
    expect(
      thumbnailUrlOf(
        yt.ThumbnailDetails(
          default_: thumb('default.jpg'),
          medium: thumb('mqdefault.jpg'),
          high: thumb('hqdefault.jpg'),
        ),
      ),
      '$_base/mqdefault.jpg',
    );
    expect(
      thumbnailUrlOf(yt.ThumbnailDetails(default_: thumb('default.jpg'))),
      '$_base/default.jpg',
    );
    expect(thumbnailUrlOf(null), isNull);
  });

  test('upgrades cached default thumbnails to medium', () async {
    final cache = VideoCacheRepository(MemoryEntryStore());
    Video video(String id, String? thumbnail) =>
        Video(videoId: id, channelId: 'c', thumbnailUrl: thumbnail);
    await cache.saveVideos({
      'a': video('a', '$_base/default.jpg'),
      'b': video('b', '$_base/default_live.jpg'),
      'c': video('c', '$_base/hqdefault.jpg'),
      'd': video('d', null),
    });

    final loaded = await cache.loadCachedVideos();
    expect(loaded['a']!.thumbnailUrl, '$_base/mqdefault.jpg');
    expect(loaded['b']!.thumbnailUrl, '$_base/mqdefault_live.jpg');
    expect(loaded['c']!.thumbnailUrl, '$_base/hqdefault.jpg');
    expect(loaded['d']!.thumbnailUrl, isNull);
  });
}
