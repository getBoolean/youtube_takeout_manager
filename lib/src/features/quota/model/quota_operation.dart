/// YouTube Data API v3 operations and their quota costs.
///
/// Costs from https://developers.google.com/youtube/v3/determine_quota_cost
enum QuotaOperation {
  deleteComment(50),
  deleteLiveChat(50),
  videosList(1),
  channelsList(1);

  const QuotaOperation(this.cost);
  final int cost;
}
