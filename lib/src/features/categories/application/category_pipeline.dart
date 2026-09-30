import 'dart:math';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import '../data/ai_errors.dart';
import '../data/typesafe_repository.dart';
import '../domain/category_path.dart';
import '../domain/channel_category.dart';
import '../domain/channel_evidence.dart';
import '../domain/youtube_taxonomy.dart';
import '../domain/youtube_topics.dart';
import 'ai_tiers.dart';

/// A channel to categorize: its key, what's known about it, and YouTube's
/// topics for it.
typedef ChannelInput = ({
  String key,
  ChannelEvidence evidence,
  List<String> topicUrls,
});

/// Jev, and the key to ask it with.
typedef JevAccess = ({TypeSafeRepository repository, String apiKey});

/// How sure Jev must be, of YouTube's category fitting or of its own pick,
/// to go with it.
const jevThreshold = 0.6;

/// YouTube's categories Jev checks at most, of those a channel's topics
/// give.
const _maxChecked = 3;

/// The option for "none of these sub-categories fits better".
const _general = '_none';

/// Picks a channel's category, cheapest step first: YouTube's topics, then,
/// with [jev], Jev's check of them and its own pick from [taxonomy].
/// Throws an [AiTierFailure] naming the service when an AI step can't be
/// done.
class CategoryPipeline {
  final Taxonomy taxonomy;
  final JevAccess? jev;
  final DateTime Function() _now;

  CategoryPipeline({required this.taxonomy, this.jev, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// The steps it takes.
  Set<CategorizationTier> get tiers => {
    CategorizationTier.youtube,
    if (jev != null) CategorizationTier.jev,
  };

  Future<ChannelCategory> categorize(ChannelInput input) async {
    final candidates = youtubeCandidates(input.topicUrls);
    ChannelCategory result({
      CategoryPath? path,
      CategorySource source = CategorySource.youtube,
      double? jevAgreed,
      double? confidence,
      List<ScoredPath> runnersUp = const [],
    }) => ChannelCategory(
      path: path,
      source: source,
      jevAgreed: jevAgreed,
      confidence: confidence,
      runnersUp: runnersUp,
      tried: tiers,
      hadTopics: input.topicUrls.isNotEmpty,
      decidedAt: _now().toUtc(),
    );

    final jev = this.jev;
    if (jev == null) return result(path: candidates.firstOrNull);

    final state = input.evidence.toState();
    final checked = candidates.take(_maxChecked).toList();
    final parents = {
      for (final parent in taxonomy.parents) _key(parent): parent,
    };
    final answers = await _askJev(jev, state, {
      for (final (i, candidate) in checked.indexed)
        'fits_$i': JevNoul(
          'Does the category "${candidate.label}" describe the videos this '
          'channel makes and the ones the user watched from it?',
          whenTrue: 'It clearly describes most of them.',
          whenFalse: 'It does not, or only a small part of them.',
        ),
      'parent': JevChoice(
        'Which category best describes the videos this channel makes and '
        'the ones the user watched from it?',
        {
          for (final MapEntry(:key, value: parent) in parents.entries)
            key: _describe(parent),
        },
      ),
    });

    // YouTube's category Jev agrees with most, if it agrees enough.
    CategoryPath? agreed;
    double? agreement;
    for (final (i, candidate) in checked.indexed) {
      if (answers['fits_$i'] case NoulAnswer(
        :final yes,
      ) when agreement == null || yes > agreement) {
        agreed = candidate;
        agreement = yes;
      }
    }
    if (agreed != null && agreement! >= jevThreshold) {
      return result(path: agreed, jevAgreed: agreement);
    }

    // Else Jev's own pick: a category, then a sub-category within it.
    final fallback = result(path: candidates.firstOrNull, jevAgreed: agreement);
    final parentAnswer = answers['parent'];
    if (parentAnswer is! ChoiceAnswer) return fallback;
    final parent = parents[parentAnswer.choice];
    if (parent == null) return fallback;
    final parentOdds =
        parentAnswer.probabilities[parentAnswer.choice] ??
        parentAnswer.confidence;
    final otherParents = [
      for (final MapEntry(:key, :value) in parentAnswer.probabilities.entries)
        if (key != parentAnswer.choice && parents[key] != null)
          ScoredPath(path: CategoryPath(parents[key]!), score: value),
    ]..sort((a, b) => b.score.compareTo(a.score));

    final children = {
      for (final child in taxonomy.childrenOf(parent)) _key(child): child,
    };
    if (children.isEmpty) {
      return parentOdds >= jevThreshold
          ? result(
              path: CategoryPath(parent),
              source: CategorySource.jev,
              jevAgreed: agreement,
              confidence: parentOdds,
              runnersUp: otherParents.take(3).toList(),
            )
          : fallback;
    }

    final childAnswer = (await _askJev(jev, state, {
      'child': JevChoice(
        'Which kind of $parent best describes the videos this channel '
        'makes and the ones the user watched from it?',
        {
          for (final MapEntry(:key, value: child) in children.entries)
            key: child,
          _general: 'None of these; just $parent in general',
        },
      ),
    }))['child'];
    if (childAnswer is! ChoiceAnswer) return fallback;
    double score(double childOdds) => sqrt(parentOdds * childOdds);
    final childOdds =
        childAnswer.probabilities[childAnswer.choice] ?? childAnswer.confidence;
    final pick = childAnswer.choice == _general
        ? CategoryPath(parent)
        : children[childAnswer.choice] == null
        ? null
        : CategoryPath(parent, children[childAnswer.choice]);
    if (pick == null || score(childOdds) < jevThreshold) return fallback;

    final runnersUp = [
      for (final MapEntry(:key, :value) in childAnswer.probabilities.entries)
        if (key != childAnswer.choice)
          ScoredPath(
            path: key == _general
                ? CategoryPath(parent)
                : CategoryPath(parent, children[key] ?? key),
            score: score(value),
          ),
      ...otherParents.take(1),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return result(
      path: pick,
      source: CategorySource.jev,
      jevAgreed: agreement,
      confidence: score(childOdds),
      runnersUp: runnersUp.take(3).toList(),
    );
  }

  static Future<Map<String, JevAnswer>> _askJev(
    JevAccess jev,
    Object state,
    Map<String, JevQuestion> questions,
  ) async {
    try {
      return await jev.repository.ask(
        apiKey: jev.apiKey,
        state: state,
        questions: questions,
      );
    } on AiFailure catch (e) {
      throw AiTierFailure(AiService.jev, e);
    }
  }

  /// A category and its sub-categories, for Jev to pick between them.
  String _describe(String parent) {
    final children = taxonomy.childrenOf(parent);
    return children.isEmpty ? parent : '$parent: ${children.join(', ')}';
  }

  /// An option key for [name]: Jev reads keys, so they say what they are.
  static String _key(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
}
