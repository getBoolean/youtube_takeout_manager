import 'package:dart_mappable/dart_mappable.dart';

import 'category_path.dart';

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

  /// Whether Claude was asked for tags, so it's asked once.
  final bool tagsTried;

  /// Whether the user added or removed a tag: then they're never replaced.
  final bool tagsEditedByUser;

  /// The fingerprint of each step's prompt that decided the category, by
  /// step name, so a changed prompt has it redone.
  final Map<String, String> prompts;

  /// The fingerprint of the prompt that named the tags.
  final String? tagsPrompt;

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
  });

  /// Whether an AI chose it, rather than YouTube's topics.
  bool get isAi =>
      source == CategorySource.jev || source == CategorySource.claude;

  /// Whether the user decided it: chose it, or accepted or kept one.
  bool get isDecided =>
      userDecision != UserDecision.none || source == CategorySource.user;
}
