import 'package:dart_mappable/dart_mappable.dart';

import 'category_path.dart';
import 'name_key.dart';

part 'channel_category.mapper.dart';

/// Where a channel's category came from.
@MappableEnum(defaultValue: CategorySource.youtube)
enum CategorySource {
  /// The topics YouTube gives the channel.
  youtube,

  /// Jev's pick from the known categories.
  jev,

  /// Claude's.
  claude,

  /// Chosen or typed by the user.
  user,
}

/// What the user said to an AI's suggestion for a channel.
@MappableEnum(defaultValue: UserDecision.none)
enum UserDecision { none, accepted, denied }

/// A step of categorizing, available or not, and tried or not.
@MappableEnum(defaultValue: CategorizationTier.youtube)
enum CategorizationTier { youtube, jev, claude }

/// The most tags a channel has.
const maxTags = 5;

/// The longest a tag can be.
const maxTagName = 40;

/// A category and how likely it is.
@MappableClass()
class ScoredPath with ScoredPathMappable {
  final CategoryPath path;
  final double score;

  const ScoredPath({required this.path, required this.score});
}

/// A channel's category, and how it was decided.
@MappableClass()
class ChannelCategory with ChannelCategoryMappable {
  /// Null when nothing could tell.
  final CategoryPath? path;
  final CategorySource source;

  /// How sure Jev was that YouTube's category fits, when it checked.
  final double? jevAgreed;

  /// How sure Jev was of its own pick.
  final double? confidence;

  /// The categories Jev found next most likely.
  final List<ScoredPath> runnersUp;

  /// Claude's reason, in a few words.
  final String? reason;

  /// The steps there were when it was decided, so a step added later can
  /// have a go.
  final Set<CategorizationTier> tried;

  /// Whether YouTube had given the channel topics then.
  final bool hadTopics;
  final UserDecision userDecision;
  final DateTime decidedAt;

  /// Up to [maxTags] specific things the channel is about, such as a game or
  /// a series; Claude names them.
  final List<String> tags;

  /// Whether AI was asked for tags, so it's asked once.
  final bool tagsTried;

  /// Whether the user added or removed a tag: then AI never names them
  /// again, only checks the tags the user defined.
  final bool tagsEditedByUser;

  /// The fingerprint of each step's prompt that decided the category, by
  /// step name, so a changed prompt has it redone.
  final Map<String, String> prompts;

  /// The fingerprint of the prompt that named the tags, as kept before
  /// [tagsPrompts]; read only.
  final String? tagsPrompt;

  /// The fingerprint of each step's prompt that made the tags, by step
  /// name, so a changed prompt has them redone.
  final Map<String, String> tagsPrompts;

  /// Whether Jev found the channel is about something no tag names, and
  /// Claude wasn't there to name it: Claude is asked once it is.
  final bool tagsAwaitClaude;

  /// When the tags were made or last checked, as of the tags there were
  /// then: a tag the user defines or changes after is checked.
  final DateTime? tagsCheckedAt;

  /// The tags the user put on this channel, and took off it, by `nameKey`:
  /// AI never takes off the first, nor puts back the second.
  final Set<String> tagsAddedByUser;
  final Set<String> tagsRemovedByUser;

  const ChannelCategory({
    this.path,
    this.source = CategorySource.youtube,
    this.jevAgreed,
    this.confidence,
    this.runnersUp = const [],
    this.reason,
    this.tried = const {},
    this.hadTopics = false,
    this.userDecision = UserDecision.none,
    required this.decidedAt,
    this.tags = const [],
    this.tagsTried = false,
    this.tagsEditedByUser = false,
    this.prompts = const {},
    this.tagsPrompt,
    this.tagsPrompts = const {},
    this.tagsAwaitClaude = false,
    this.tagsCheckedAt,
    this.tagsAddedByUser = const {},
    this.tagsRemovedByUser = const {},
  });

  /// Whether an AI chose it, rather than YouTube's topics.
  bool get isAi =>
      source == CategorySource.jev || source == CategorySource.claude;

  /// Whether the user decided it: chose it, or accepted or kept one.
  bool get isDecided =>
      userDecision != UserDecision.none || source == CategorySource.user;

  /// The tags AI may never take off, by `nameKey`: those the user added; on
  /// a channel they edited before what they added was kept, every tag.
  Set<String> get protectedTagKeys =>
      tagsEditedByUser && tagsAddedByUser.isEmpty && tagsRemovedByUser.isEmpty
      ? {for (final tag in tags) nameKey(tag)}
      : tagsAddedByUser;

  /// This category with [other]'s tags and all that's known about them.
  ChannelCategory withTagsOf(ChannelCategory other) => copyWith(
    tags: other.tags,
    tagsTried: other.tagsTried,
    tagsEditedByUser: other.tagsEditedByUser,
    tagsPrompt: other.tagsPrompt,
    tagsPrompts: other.tagsPrompts,
    tagsAwaitClaude: other.tagsAwaitClaude,
    tagsCheckedAt: other.tagsCheckedAt,
    tagsAddedByUser: other.tagsAddedByUser,
    tagsRemovedByUser: other.tagsRemovedByUser,
  );

  /// This category with what AI made of its tags forgotten: tags the user
  /// edited stay, with what they added and removed; others go, as never
  /// asked for.
  ChannelCategory withoutAiTags() => tagsEditedByUser
      ? copyWith(
          tagsPrompt: null,
          tagsPrompts: const {},
          tagsAwaitClaude: false,
          tagsCheckedAt: null,
        )
      : copyWith(
          tags: const [],
          tagsTried: false,
          tagsPrompt: null,
          tagsPrompts: const {},
          tagsAwaitClaude: false,
          tagsCheckedAt: null,
        );
}
