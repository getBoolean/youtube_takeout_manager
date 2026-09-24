import 'package:googleapis/youtube/v3.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'youtube_deletion_repository.g.dart';

@Riverpod(keepAlive: true)
YoutubeDeletionRepository youtubeDeletionRepository(Ref ref) =>
    YoutubeDeletionRepository();

/// Deletes YouTube comments and live chat messages
/// via the YouTube Data API v3.
///
/// Live chat messages from Takeout are deletable via `comments.delete` because
/// Google treats them under the same activity type. `liveChatMessages.delete`
/// is not used — it only works on messages in currently-active broadcasts.
///
/// Each delete call costs 50 quota units.
class YoutubeDeletionRepository {
  /// Deletes a single item from YouTube.
  ///
  /// Returns `succeeded: true` on success.
  /// On failure, returns `succeeded: false` with an error description.
  /// If the error is a quota exceeded error, `quotaExceeded` is true.
  Future<({bool succeeded, bool quotaExceeded, String? error})> deleteItem(
    http.Client client,
    String itemId,
  ) async {
    final youtube = YouTubeApi(client);
    try {
      await youtube.comments.delete(itemId);
      return (succeeded: true, quotaExceeded: false, error: null);
    } on DetailedApiRequestError catch (e) {
      final isQuota =
          e.status == 403 &&
          (e.message?.contains('quota') == true ||
              e.errors.any(
                    (err) =>
                        err.reason == 'quotaExceeded' ||
                        err.reason == 'dailyLimitExceeded',
                  ) ==
                  true);
      return (
        succeeded: false,
        quotaExceeded: isQuota,
        error: e.message ?? 'API error ${e.status}',
      );
    } catch (e) {
      return (succeeded: false, quotaExceeded: false, error: e.toString());
    }
  }
}
