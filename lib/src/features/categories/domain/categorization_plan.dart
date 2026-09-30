import 'channel_category.dart';

/// How sure Jev must be, of YouTube's category fitting, of its own pick,
/// or of a sub-category matching one Claude named, to go with it.
const jevThreshold = 0.6;

/// The AI steps: they can categorize a channel from its name and the
/// videos watched from it, without topics.
const _aiTiers = {CategorizationTier.jev, CategorizationTier.claude};

/// Whether a channel with the category [existing] (none yet when null)
/// should be categorized, given the steps [available] now and whether it
/// [hasTopics] from YouTube. Never once the user decided; again only when
/// something new could change the outcome.
bool needsCategorizing(
  ChannelCategory? existing, {
  required Set<CategorizationTier> available,
  required bool hasTopics,
}) {
  final ai = available.intersection(_aiTiers);
  if (existing == null) return hasTopics || ai.isNotEmpty;
  if (existing.userDecision != UserDecision.none) return false;
  final untried = ai.difference(existing.tried);
  if (existing.path == null) {
    return (hasTopics && !existing.hadTopics) || untried.isNotEmpty;
  }
  if (existing.source != CategorySource.youtube) return false;
  // YouTube's pick gets Jev's check once Jev is there, and Claude's once
  // Claude is, when Jev doubted it and had nothing better.
  final agreed = existing.jevAgreed;
  return agreed == null
      ? untried.contains(CategorizationTier.jev)
      : agreed < jevThreshold && untried.contains(CategorizationTier.claude);
}
