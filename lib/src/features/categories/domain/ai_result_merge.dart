import 'channel_category.dart';

/// What a channel's category becomes when an AI run answers [result] for it
/// while it has [existing]: a category the user decided stays, and only
/// the run's tags are taken; tags the user edited stay; tags the run didn't
/// ask for stay as they were. Otherwise it's the run's.
ChannelCategory mergeAiResult(
  ChannelCategory? existing,
  ChannelCategory result,
) {
  if (existing == null) return result;
  final category = existing.isDecided ? existing : result;
  final tags = existing.tagsEditedByUser || !result.tagsTried
      ? existing
      : result;
  return category.copyWith(
    tags: tags.tags,
    tagsTried: tags.tagsTried,
    tagsEditedByUser: tags.tagsEditedByUser,
    tagsPrompt: tags.tagsPrompt,
  );
}
