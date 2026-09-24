/// How the user chose to delete items from YouTube.
enum DeletionMethod {
  /// Add to the deletion queue and choose a method later.
  addToQueue,

  /// Delete via a script run in the browser on Google My Activity. No quota.
  myActivityScript,

  /// Delete via the YouTube Data API. Limited by the daily quota.
  youtubeApi,
}
