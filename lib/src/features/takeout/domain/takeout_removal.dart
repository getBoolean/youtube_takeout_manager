import 'takeout_channel.dart';

/// What removing a saved takeout removes.
class TakeoutRemoval {
  final TakeoutSummary summary;

  /// Its channels that no other saved takeout has, whose queued deletions
  /// and sign-ins go with it.
  final Set<String> orphanedChannelIds;
  final int queuedCount;

  /// The saved sign-ins removed with it.
  final Set<String> signInIds;

  const TakeoutRemoval({
    required this.summary,
    required this.orphanedChannelIds,
    required this.queuedCount,
    required this.signInIds,
  });
}
