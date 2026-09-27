import 'dart:math';

import 'package:googleapis/youtube/v3.dart' as yt;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';

import '../domain/video.dart';

part 'youtube_video_repository.g.dart';

@Riverpod(keepAlive: true)
YoutubeVideoRepository youtubeVideoRepository(Ref ref) =>
    YoutubeVideoRepository();

/// The thumbnail to show: `medium` (320x180, 16:9) stays sharp in group
/// headers; `default` is only 120x90, letterboxed.
String? thumbnailUrlOf(yt.ThumbnailDetails? thumbnails) =>
    thumbnails?.medium?.url ??
    thumbnails?.high?.url ??
    thumbnails?.default_?.url;

/// Fetches YouTube video metadata via the YouTube Data API v3.
///
/// Each `videos.list` call costs 1 quota unit and accepts up to 50 video IDs.
class YoutubeVideoRepository {
  /// How many video IDs one `videos.list` call takes.
  static const batchSize = 50;
  static const _delayBetweenRequests = Duration(milliseconds: 100);

  /// Streams individual [Video] objects as they are fetched from the API.
  ///
  /// Batches requests in groups of [batchSize] for efficiency, but yields
  /// each video individually as it is parsed from the response. Calls
  /// [onResponse] as each request is answered, so its quota can be counted
  /// as it's used.
  Stream<Video> fetchVideoMetadataStream(
    http.Client authClient,
    Set<String> videoIds, {
    void Function()? onResponse,
  }) async* {
    final youtube = yt.YouTubeApi(authClient);
    final idList = videoIds.toList();

    for (var i = 0; i < idList.length; i += batchSize) {
      final batch = idList.sublist(i, min(i + batchSize, idList.length));

      try {
        final response = await youtube.videos.list(['snippet'], id: batch);
        onResponse?.call();

        for (final item in response.items ?? <yt.Video>[]) {
          if (item.id == null || item.snippet == null) continue;
          final snippet = item.snippet!;
          yield Video(
            videoId: item.id!,
            channelId: snippet.channelId ?? '',
            channelTitle: snippet.channelTitle,
            title: snippet.title,
            description: snippet.description,
            thumbnailUrl: thumbnailUrlOf(snippet.thumbnails),
            publishedAt: snippet.publishedAt,
          );
        }
      } catch (e) {
        // A sign-in that stopped working fails every batch; let it through.
        if (isSignInFailure(e)) rethrow;
        // Continue with remaining batches on error
      }

      if (i + batchSize < idList.length) {
        await Future.delayed(_delayBetweenRequests);
      }
    }
  }
}
