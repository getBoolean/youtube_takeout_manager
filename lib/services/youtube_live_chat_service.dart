import 'package:googleapis/youtube/v3.dart';
import 'package:http/http.dart' as http;

import '../models/api_deletion_result.dart';

/// Service for deleting YouTube live chat messages via the YouTube Data API v3.
///
/// Note: Live chat messages may not be deletable after the stream has ended.
/// The service handles 403/404 errors gracefully by marking those as failed
/// rather than aborting the entire batch.
class YoutubeLiveChatService {
  static const _quotaCostPerDelete = 50;
  static const _dailyQuotaLimit = 10000;
  static const _delayBetweenRequests = Duration(milliseconds: 100);

  int _quotaUsed = 0;

  /// Deletes a single live chat message by ID.
  Future<void> deleteLiveChatMessage(
    http.Client authClient,
    String messageId,
  ) async {
    final youtube = YouTubeApi(authClient);
    await youtube.liveChatMessages.delete(messageId);
    _quotaUsed += _quotaCostPerDelete;
  }

  /// Deletes live chat messages in batch, yielding progress after each attempt.
  ///
  /// Messages that are no longer deletable (stream ended) are counted as failed
  /// rather than causing the batch to abort.
  Stream<ApiDeletionResult> deleteLiveChatMessagesBatch(
    http.Client authClient,
    List<String> messageIds,
  ) async* {
    final youtube = YouTubeApi(authClient);
    final total = messageIds.length;
    var succeeded = 0;
    var failed = 0;
    final failedIds = <String>[];

    for (final id in messageIds) {
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
        await youtube.liveChatMessages.delete(id);
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
