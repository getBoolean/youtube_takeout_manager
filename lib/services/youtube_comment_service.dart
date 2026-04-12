import 'package:googleapis/youtube/v3.dart';
import 'package:http/http.dart' as http;

import '../models/api_deletion_result.dart';

/// Service for deleting YouTube comments via the YouTube Data API v3.
///
/// Each `comments.delete` call costs 50 quota units.
/// Daily quota is 10,000 units, so max ~200 deletes per day.
class YoutubeCommentService {
  static const _quotaCostPerDelete = 50;
  static const _dailyQuotaLimit = 10000;
  static const _delayBetweenRequests = Duration(milliseconds: 100);

  int _quotaUsed = 0;

  /// Deletes a single comment by ID.
  Future<void> deleteComment(http.Client authClient, String commentId) async {
    final youtube = YouTubeApi(authClient);
    await youtube.comments.delete(commentId);
    _quotaUsed += _quotaCostPerDelete;
  }

  /// Deletes comments in batch, yielding progress after each deletion.
  ///
  /// Respects YouTube API quota limits and adds a small delay between requests.
  Stream<ApiDeletionResult> deleteCommentsBatch(
    http.Client authClient,
    List<String> commentIds,
  ) async* {
    final youtube = YouTubeApi(authClient);
    final total = commentIds.length;
    var succeeded = 0;
    var failed = 0;
    final failedIds = <String>[];

    for (final id in commentIds) {
      if (_quotaUsed + _quotaCostPerDelete > _dailyQuotaLimit) {
        yield ApiDeletionResult(
          total: total,
          succeeded: succeeded,
          failed: failed,
          remaining: total - succeeded - failed,
          failedIds: failedIds,
          errorMessage: 'Daily API quota limit reached (~200 deletes/day)',
        );
        return;
      }

      try {
        await youtube.comments.delete(id);
        _quotaUsed += _quotaCostPerDelete;
        succeeded++;
      } catch (e) {
        failed++;
        failedIds.add(id);
      }

      yield ApiDeletionResult(
        total: total,
        succeeded: succeeded,
        failed: failed,
        remaining: total - succeeded - failed,
        failedIds: failedIds,
      );

      if (succeeded + failed < total) {
        await Future.delayed(_delayBetweenRequests);
      }
    }
  }
}
