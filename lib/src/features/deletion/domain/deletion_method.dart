/// How the user chose to delete queued items from YouTube.
enum DeletionMethod {
  /// Delete via a script run in the browser on Google My Activity. No quota.
  myActivityScript,

  /// Delete via the YouTube Data API. Limited by the daily quota.
  youtubeApi,
}
