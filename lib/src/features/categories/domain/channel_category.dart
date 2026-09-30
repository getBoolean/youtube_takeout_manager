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
}

/// What the user said to an AI's suggestion for a channel.
@MappableEnum(defaultValue: UserDecision.none)
enum UserDecision { none, accepted, denied }

/// A step of categorizing, available or not, and tried or not.
@MappableEnum(defaultValue: CategorizationTier.youtube)
enum CategorizationTier { youtube, jev, claude }

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
  });

  /// Whether an AI chose it, rather than YouTube's topics.
  bool get isAi =>
      source == CategorySource.jev || source == CategorySource.claude;
}
