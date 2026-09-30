import 'package:googleapis/youtube/v3.dart' as yt;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/channel_details.dart';

part 'youtube_channel_repository.g.dart';

/// A channel's picture, if it has one, and what it says about itself.
typedef ChannelSnippet = ({String? thumbnailUrl, ChannelDetails details});

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

  /// Fetches each of [channelIds]' picture, topics and description, in
  /// one request per 50 channels: topics cost nothing more than pictures.
  ///
  /// Returns the channels that were found. A request that fails is thrown,
  /// so its channels aren't taken to be gone.
  Future<Map<String, ChannelSnippet>> fetchChannelSnippets(
    http.Client authClient,
    Set<String> channelIds,
  ) async {
    final youtube = yt.YouTubeApi(authClient);
    final results = <String, ChannelSnippet>{};
    final idList = channelIds.toList();

    for (var i = 0; i < idList.length; i += _batchSize) {
      final batch = idList.sublist(i, (i + _batchSize).clamp(0, idList.length));

      final response = await youtube.channels.list([
        'snippet',
        'topicDetails',
      ], id: batch);
      for (final item in response.items ?? <yt.Channel>[]) {
        final id = item.id;
        if (id == null) continue;
        results[id] = (
          thumbnailUrl: item.snippet?.thumbnails?.default_?.url,
          details: ChannelDetails.fromApi(
            topicCategories: item.topicDetails?.topicCategories,
            description: item.snippet?.description,
          ),
        );
      }

      if (i + _batchSize < idList.length) {
        await Future.delayed(_delayBetweenRequests);
      }
    }

    return results;
  }
}
