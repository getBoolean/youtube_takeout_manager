import '../domain/channel_category.dart';
import '../domain/channel_evidence.dart';
import '../domain/youtube_topics.dart';

/// A channel to categorize: its key, what's known about it, and YouTube's
/// topics for it.
typedef ChannelInput = ({
  String key,
  ChannelEvidence evidence,
  List<String> topicUrls,
});

/// Picks a channel's category, cheapest step first: YouTube's topics, then,
/// when their keys are set, Jev's check and pick, then Claude.
class CategoryPipeline {
  final DateTime Function() now;

  CategoryPipeline({DateTime Function()? now}) : now = now ?? DateTime.now;

  /// The steps it takes.
  Set<CategorizationTier> get tiers => const {CategorizationTier.youtube};

  Future<ChannelCategory> categorize(ChannelInput input) async {
    final candidates = youtubeCandidates(input.topicUrls);
    return ChannelCategory(
      path: candidates.firstOrNull,
      source: CategorySource.youtube,
      tried: tiers,
      hadTopics: input.topicUrls.isNotEmpty,
      decidedAt: now().toUtc(),
    );
  }
}
