import 'package:googleapis/youtube/v3.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/data/quota_errors.dart';
import '../domain/deletion_outcome.dart';

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
  Future<DeletionOutcome> deleteItem(http.Client client, String itemId) async {
    final youtube = YouTubeApi(client);
    try {
      await youtube.comments.delete(itemId);
      return const Deleted();
    } catch (e) {
      if (isSignInFailure(e)) return const SignInFailed();
      if (e is DetailedApiRequestError) {
        final message = e.message ?? 'API error ${e.status}';
        return isQuotaExceeded(e) ? QuotaExceeded(message) : Failed(message);
      }
      return Failed(e.toString());
    }
  }
}
