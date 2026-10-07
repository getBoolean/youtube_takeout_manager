import 'channel_category.dart';

/// How sure Jev must be, of YouTube's category fitting, of its own pick,
/// or of a sub-category matching one Claude named, to go with it.
const jevThreshold = 0.6;

/// The AI steps: they can categorize a channel from its name and the
/// videos watched from it, without topics.
const _aiTiers = {CategorizationTier.jev, CategorizationTier.claude};

/// What a run does for a channel: nothing, categorize it (with its tags,
/// when AI is there), ask for its tags alone, or ask Claude for the tags
/// Jev found no name for.
enum ChannelWork { none, categorize, tags, claudeTags }

/// What a run does for a channel, whether it's doing it again because a
/// prompt changed, and whether Jev checks it for the tags the user defined
/// or changed since it was last checked.
typedef WorkPlan = ({ChannelWork work, bool redo, bool checkTags});

const _nothing = (work: ChannelWork.none, redo: false, checkTags: false);

WorkPlan _do(ChannelWork work, {bool redo = false}) =>
    (work: work, redo: redo, checkTags: false);

/// The AI services whose answers made [category]'s tags: redoing them
/// without one would lose what that one said. Tags named before each
/// step's prompt was kept were Claude's.
Set<CategorizationTier> _tagsMadeBy(ChannelCategory category) =>
    category.tagsPrompts.isEmpty
    ? {CategorizationTier.claude}
    : {
        for (final step in category.tagsPrompts.keys)
          step.startsWith('jev')
              ? CategorizationTier.jev
              : CategorizationTier.claude,
      };

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
/// YouTube, each step's prompt [fingerprints] now, by step name, and when a
/// tag the user defined was last defined or changed
/// ([userTagsChangedAt]).
///
/// A category the user decided is never redone; neither are tags they
/// edited, though Jev checks them for the user's tags. An AI output made
/// with a prompt that has since changed, or before prompts were kept, is
/// redone, once the services that made it are there. Otherwise a channel is
/// looked at again only when something new could change it; with Jev or
/// Claude there, a channel with a category whose tags were never asked for,
/// or were named with an older prompt, gets its tags alone; and with Claude
/// there, one Jev found is about something no tag names gets Claude's.
/// A run with no AI does nothing about tags.
WorkPlan planWork(
  ChannelCategory? existing, {
  required Set<CategorizationTier> available,
  required bool hasTopics,
  required Map<String, String> fingerprints,
  DateTime? userTagsChangedAt,
}) {
  final ai = available.intersection(_aiTiers);
  if (existing == null) {
    return hasTopics || ai.isNotEmpty ? _do(ChannelWork.categorize) : _nothing;
  }

  WorkPlan check() {
    final checkedAt = existing.tagsCheckedAt;
    final due =
        available.contains(CategorizationTier.jev) &&
        userTagsChangedAt != null &&
        (checkedAt == null || userTagsChangedAt.isAfter(checkedAt));
    return due
        ? (work: ChannelWork.none, redo: false, checkTags: true)
        : _nothing;
  }

  WorkPlan tags() {
    if (ai.isEmpty || existing.path == null || existing.tagsEditedByUser) {
      return check();
    }
    if (!existing.tagsTried) return _do(ChannelWork.tags);
    final stale = existing.tagsPrompts.isEmpty
        ? true
        : existing.tagsPrompts.entries.any(
            (p) => fingerprints[p.key] != p.value,
          );
    if (stale && ai.containsAll(_tagsMadeBy(existing))) {
      return _do(ChannelWork.tags, redo: true);
    }
    if (existing.tagsAwaitClaude &&
        available.contains(CategorizationTier.claude)) {
      return _do(ChannelWork.claudeTags);
    }
    return check();
  }

  if (existing.isDecided) return tags();

  final stale =
      existing.prompts.entries.any((p) => fingerprints[p.key] != p.value) ||
      (existing.prompts.isEmpty &&
          (existing.isAi || existing.jevAgreed != null));
  if (stale && ai.containsAll(_madeBy(existing))) {
    return _do(ChannelWork.categorize, redo: true);
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
  return again ? _do(ChannelWork.categorize) : tags();
}
