import 'category_path.dart';
import 'channel_category.dart';
import 'name_key.dart';
import 'sub_category.dart';
import 'tag_name.dart';

/// Channels' categories, the sub-categories made for them, and the tags
/// there are, as kept.
typedef AiResults = ({
  Map<String, ChannelCategory> categories,
  Map<String, List<SubCategory>> custom,
  Map<String, TagName> tags,
});

/// [stored] with what AI made cleared, as of [now]:
/// - a category Jev or Claude chose goes back to YouTube's ([youtubeOf] the
///   channel's key), or to none, with no AI step counted as tried;
/// - YouTube's categories lose Jev's agreement;
/// - tags lose the ones AI named;
/// - sub-categories and tags AI made that no channel still has go.
///
/// What the user decided stays: their categories (an AI suggestion they
/// took among them), tags they edited, and names they typed.
AiResults clearAiResults(
  AiResults stored, {
  required List<CategoryPath> Function(String channelKey) youtubeOf,
  required DateTime now,
}) {
  final categories = {
    for (final MapEntry(:key, :value) in stored.categories.entries)
      key: _cleared(value, youtube: () => youtubeOf(key).firstOrNull, now: now),
  };

  final usedChildren = {
    for (final category in categories.values)
      if (category.path case CategoryPath(:final parent, child: final child?))
        (parent, nameKey(child)),
  };
  final custom = <String, List<SubCategory>>{};
  for (final MapEntry(key: parent, value: children) in stored.custom.entries) {
    final kept = [
      for (final child in children)
        if (child.origin == NameOrigin.user ||
            usedChildren.contains((parent, nameKey(child.name))))
          child,
    ];
    if (kept.isNotEmpty) custom[parent] = kept;
  }

  final usedTags = {
    for (final category in categories.values)
      for (final tag in category.tags) nameKey(tag),
  };
  final tags = {
    for (final MapEntry(:key, :value) in stored.tags.entries)
      if (value.origin == NameOrigin.user || usedTags.contains(key)) key: value,
  };
  return (categories: categories, custom: custom, tags: tags);
}

/// [category] with what AI made cleared, YouTube's category being
/// [youtube]'s.
ChannelCategory _cleared(
  ChannelCategory category, {
  required CategoryPath? Function() youtube,
  required DateTime now,
}) {
  var cleared = category;
  if (!category.isDecided) {
    cleared = category.isAi
        ? ChannelCategory(
            path: youtube(),
            tried: const {CategorizationTier.youtube},
            hadTopics: category.hadTopics,
            decidedAt: now,
          )
        : category.copyWith(
            jevAgreed: null,
            prompts: const {},
            tried: category.tried.intersection({CategorizationTier.youtube}),
          );
  }
  return category.tagsEditedByUser
      ? cleared.copyWith(
          tags: category.tags,
          tagsTried: category.tagsTried,
          tagsEditedByUser: true,
          tagsPrompt: category.tagsPrompt,
        )
      : cleared.copyWith(tags: const [], tagsTried: false, tagsPrompt: null);
}

/// How many channels a clear sends back to AI: those whose category the
/// user didn't decide, or whose tags they didn't edit.
int channelsToRedo(Map<String, ChannelCategory> categories) => categories.values
    .where((category) => !category.isDecided || !category.tagsEditedByUser)
    .length;
