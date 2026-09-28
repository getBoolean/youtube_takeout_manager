import 'package:googleapis/youtube/v3.dart' as yt;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';


part 'youtube_channel_repository.g.dart';

@Riverpod(keepAlive: true)
YoutubeChannelRepository youtubeChannelRepository(Ref ref) =>
    YoutubeChannelRepository();

/// Fetches YouTube channel metadata via the YouTube Data API v3.
///
/// Each `channels.list` call costs 1 quota unit and accepts up to 50 channel IDs.
class YoutubeChannelRepository {
  static const _batchSize = 50;
  static const _delayBetweenRequests = Duration(milliseconds: 100);

  /// Returns the channel [authClient] is signed in with, or null if its
  /// account has none. Request failures are thrown.
  Future<({String id, String? title, String? handle, String? thumbnailUrl})?>
  fetchMyChannel(http.Client authClient) async {
    final response = await yt.YouTubeApi(
      authClient,
    ).channels.list(['snippet'], mine: true);
    final channel = response.items?.firstOrNull;
    final id = channel?.id;
    if (id == null) return null;
    return (
      id: id,
      title: channel?.snippet?.title,
      handle: channel?.snippet?.customUrl,
      thumbnailUrl: channel?.snippet?.thumbnails?.default_?.url,
    );
  }

  /// Fetches channel thumbnails for the given [channelIds].
  ///
  /// Returns a map of channelId → thumbnail URL for channels that were found.
  /// A request that fails is thrown, so its channels aren't taken to be
  /// gone.
  Future<Map<String, String>> fetchChannelThumbnails(
    http.Client authClient,
    Set<String> channelIds,
  ) async {
    final youtube = yt.YouTubeApi(authClient);
    final results = <String, String>{};
    final idList = channelIds.toList();

    for (var i = 0; i < idList.length; i += _batchSize) {
      final batch = idList.sublist(i, (i + _batchSize).clamp(0, idList.length));

      final response = await youtube.channels.list(['snippet'], id: batch);
      for (final item in response.items ?? <yt.Channel>[]) {
        if (item.id == null || item.snippet == null) continue;
        final url = item.snippet!.thumbnails?.default_?.url;
        if (url != null) {
          results[item.id!] = url;
        }
      }

      if (i + _batchSize < idList.length) {
        await Future.delayed(_delayBetweenRequests);
      }
    }

    return results;
  }
}
