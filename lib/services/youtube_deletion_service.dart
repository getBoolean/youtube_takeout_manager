import 'package:googleapis/youtube/v3.dart';
import 'package:http/http.dart' as http;

import '../models/deletion_item_type.dart';

/// Unified service for deleting YouTube comments and live chat messages
/// via the YouTube Data API v3.
///
/// Each delete call costs 50 quota units regardless of item type.
class YoutubeDeletionService {
  static const quotaCostPerDelete = 50;

  /// Deletes a single item from YouTube.
  ///
  /// Returns `succeeded: true` on success.
  /// On failure, returns `succeeded: false` with an error description.
  /// If the error is a quota exceeded error, `quotaExceeded` is true.
  Future<({bool succeeded, bool quotaExceeded, String? error})> deleteItem(
    http.Client client,
    String itemId,
    DeletionItemType type,
  ) async {
    final youtube = YouTubeApi(client);
    try {
      switch (type) {
        case DeletionItemType.comment:
          await youtube.comments.delete(itemId);
        case DeletionItemType.liveChat:
          await youtube.liveChatMessages.delete(itemId);
      }
      return (succeeded: true, quotaExceeded: false, error: null);
    } on DetailedApiRequestError catch (e) {
      final isQuota = e.status == 403 &&
          (e.message?.contains('quota') == true ||
              e.errors.any((err) =>
                      err.reason == 'quotaExceeded' ||
                      err.reason == 'dailyLimitExceeded') ==
                  true);
      return (
        succeeded: false,
        quotaExceeded: isQuota,
        error: e.message ?? 'API error ${e.status}',
      );
    } catch (e) {
      return (
        succeeded: false,
        quotaExceeded: false,
        error: e.toString(),
      );
    }
  }
}
