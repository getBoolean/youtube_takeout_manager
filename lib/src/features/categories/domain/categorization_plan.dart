import 'channel_category.dart';

/// How sure Jev must be, of YouTube's category fitting, of its own pick,
/// or of a sub-category matching one Claude named, to go with it.
const jevThreshold = 0.6;

/// The AI steps: they can categorize a channel from its name and the
/// videos watched from it, without topics.
const _aiTiers = {CategorizationTier.jev, CategorizationTier.claude};

/// What a run does for a channel: nothing, categorize it (with its tags,
/// when Claude is there), or ask for its tags alone.
enum ChannelWork { none, categorize, tags }

/// What a run does for a channel, and whether it's doing it again because
/// a prompt changed.
typedef WorkPlan = ({ChannelWork work, bool redo});

const _nothing = (work: ChannelWork.none, redo: false);

/// The AI services whose answers made [category]: redoing it without one
/// of them would lose what that one said.
Set<CategorizationTier> _madeBy(ChannelCategory category) => {
  if (category.source == CategorySource.claude ||
      category.prompts.containsKey('claudeCategory'))
    CategorizationTier.claude,
  if (category.source == CategorySource.jev ||
      category.jevAgreed != null ||
      category.prompts.keys.any((step) => step.startsWith('jev')))
    CategorizationTier.jev,
};

/// What a run does for a channel with the category [existing] (none yet
/// when null), given the steps [available] now, whether it [hasTopics] from
/// YouTube, and each step's prompt [fingerprints] now, by step name.
///
/// A category the user decided is never redone; neither are tags they
/// edited. An AI output made with a prompt that has since changed, or
/// before prompts were kept, is redone, once the services that made it are
/// there. Otherwise a channel is looked at again only when something new
/// could change it; and with Claude there, a channel whose tags were never
/// asked for, or were named with an older prompt, gets its tags alone.
WorkPlan planWork(
  ChannelCategory? existing, {
  required Set<CategorizationTier> available,
  required bool hasTopics,
  required Map<String, String> fingerprints,
}) {
  final ai = available.intersection(_aiTiers);
  if (existing == null) {
    return hasTopics || ai.isNotEmpty
        ? (work: ChannelWork.categorize, redo: false)
        : _nothing;
  }

  WorkPlan tags() {
    if (!available.contains(CategorizationTier.claude) ||
        existing.tagsEditedByUser) {
      return _nothing;
    }
    if (!existing.tagsTried) return (work: ChannelWork.tags, redo: false);
    final prompt = existing.tagsPrompt;
    final current =
        prompt != null &&
        (prompt == fingerprints['claudeCategory'] ||
            prompt == fingerprints['claudeTags']);
    return current ? _nothing : (work: ChannelWork.tags, redo: true);
  }

  if (existing.isDecided) return tags();

  final stale =
      existing.prompts.entries.any((p) => fingerprints[p.key] != p.value) ||
      (existing.prompts.isEmpty &&
          (existing.isAi || existing.jevAgreed != null));
  if (stale && ai.containsAll(_madeBy(existing))) {
    return (work: ChannelWork.categorize, redo: true);
  }

  final untried = ai.difference(existing.tried);
  final bool again;
  if (existing.path == null) {
    again = (hasTopics && !existing.hadTopics) || untried.isNotEmpty;
  } else if (existing.source != CategorySource.youtube) {
    again = false;
  } else {
    // YouTube's pick gets Jev's check once Jev is there, and Claude's once
    // Claude is, when Jev doubted it and had nothing better.
    final agreed = existing.jevAgreed;
    again = agreed == null
        ? untried.contains(CategorizationTier.jev)
        : agreed < jevThreshold && untried.contains(CategorizationTier.claude);
  }
  return again ? (work: ChannelWork.categorize, redo: false) : tags();
}
