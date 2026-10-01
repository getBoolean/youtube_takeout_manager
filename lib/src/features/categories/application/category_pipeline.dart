import 'dart:math';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import '../data/ai_errors.dart';
import '../data/anthropic_repository.dart';
import '../data/typesafe_repository.dart';
import '../domain/categorization_plan.dart';
import '../domain/category_path.dart';
import '../domain/category_prompts.dart';
import '../domain/channel_category.dart';
import '../domain/channel_evidence.dart';
import '../domain/model_capabilities.dart';
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

/// Claude, the key to ask it with, and what its model can do.
typedef ClaudeAccess = ({
  AnthropicRepository repository,
  String apiKey,
  ModelCapabilities model,
});

/// YouTube's categories Jev checks at most, of those a channel's topics
/// give.
const _maxChecked = 3;

/// Sub-categories a category takes at most, keeping Jev's choices under
/// its limit.
const _maxChildren = 200;

/// The option for "none of these sub-categories fits better".
const _general = '_none';

/// Jev's pick: a category, how sure it is, and what came next.
typedef _Pick = ({CategoryPath path, double score, List<ScoredPath> runnersUp});

/// Picks a channel's category, cheapest step first: YouTube's topics; with
/// [jev], Jev's check of them, then its own pick from [taxonomy]; and with
/// [claude], Claude, only when Jev can't settle it (or, without Jev, when
/// YouTube gives no sub-category). A sub-category Claude names that
/// [taxonomy] lacks joins it, unless Jev finds it's one there already.
/// Throws an [AiTierFailure] naming the service when an AI step can't be
/// done, except for one with no usable answer for the channel: that
/// channel keeps YouTube's category, the step counted as tried.
class CategoryPipeline {
  Taxonomy _taxonomy;
  final JevAccess? jev;
  final ClaudeAccess? claude;
  final DateTime Function() _now;
  final _learned = <CategoryPath>[];

  CategoryPipeline({
    required Taxonomy taxonomy,
    this.jev,
    this.claude,
    DateTime Function()? now,
  }) : _taxonomy = taxonomy,
       _now = now ?? DateTime.now;

  /// The categories it picks from, with the sub-categories Claude added.
  Taxonomy get taxonomy => _taxonomy;

  /// The sub-categories Claude added since last asked, to keep.
  List<CategoryPath> takeLearned() {
    final learned = [..._learned];
    _learned.clear();
    return learned;
  }

  /// The steps it takes.
  Set<CategorizationTier> get tiers => {
    CategorizationTier.youtube,
    if (jev != null) CategorizationTier.jev,
    if (claude != null) CategorizationTier.claude,
  };

  ChannelCategory _result(
    ChannelInput input, {
    CategoryPath? path,
    CategorySource source = CategorySource.youtube,
    double? jevAgreed,
    double? confidence,
    List<ScoredPath> runnersUp = const [],
    String? reason,
  }) => ChannelCategory(
    path: path,
    source: source,
    jevAgreed: jevAgreed,
    confidence: confidence,
    runnersUp: runnersUp,
    reason: reason,
    tried: tiers,
    hadTopics: input.topicUrls.isNotEmpty,
    decidedAt: _now().toUtc(),
  );

  Future<ChannelCategory> categorize(ChannelInput input) async {
    try {
      return await _categorize(input);
    } on AiTierFailure catch (e) {
      if (e.failure is! AiNoAnswer) rethrow;
      // About this channel alone, such as a refusal, and paid for: asking
      // again would only pay again.
      return _result(
        input,
        path: youtubeCandidates(input.topicUrls).firstOrNull,
      );
    }
  }

  Future<ChannelCategory> _categorize(ChannelInput input) async {
    final candidates = youtubeCandidates(input.topicUrls);
    final jev = this.jev;
    if (jev == null) {
      // Without Jev to check it, YouTube's category stands; Claude only
      // names what YouTube gives no sub-category for.
      final youtube = candidates.firstOrNull;
      if (claude == null || youtube?.child != null) {
        return _result(input, path: youtube);
      }
      return _claudeCategory(input);
    }

    final state = input.evidence.toState();
    final checked = candidates.take(_maxChecked).toList();
    final answers = await _askJev(jev, state, {
      for (final (i, candidate) in checked.indexed)
        'fits_$i': JevNoul(
          'Does the category "${candidate.label}" describe the videos this '
          'channel makes and the ones the user watched from it?',
          whenTrue: 'It clearly describes most of them.',
          whenFalse: 'It does not, or only a small part of them.',
        ),
      'parent': _parentQuestion(),
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
      return _result(input, path: agreed, jevAgreed: agreement);
    }

    final pick = await _jevPick(jev, state, answers['parent']);
    if (pick != null && pick.score >= jevThreshold) {
      return _result(
        input,
        path: pick.path,
        source: CategorySource.jev,
        jevAgreed: agreement,
        confidence: pick.score,
        runnersUp: pick.runnersUp,
      );
    }
    if (claude != null) {
      return _claudeCategory(input, jevAgreed: agreement);
    }
    return _result(input, path: candidates.firstOrNull, jevAgreed: agreement);
  }

  /// Another category than [current], for a channel the user says it's
  /// wrong for: Claude's, told so, else Jev's pick leaving [current] out.
  Future<ChannelCategory> suggestInstead(
    ChannelInput input,
    CategoryPath? current,
  ) async {
    if (claude != null) return _claudeCategory(input, inaccurate: current);
    final jev = this.jev;
    if (jev == null) throw StateError('No AI to ask');
    final pick = await _jevPick(
      jev,
      input.evidence.toState(),
      null,
      exclude: current,
    );
    if (pick == null) throw const AiTierFailure(AiService.jev, AiNoAnswer());
    return _result(
      input,
      path: pick.path,
      source: CategorySource.jev,
      confidence: pick.score,
      runnersUp: pick.runnersUp,
    );
  }

  JevChoice _parentQuestion({CategoryPath? exclude}) => JevChoice(
    'Which category best describes the videos this channel makes and the '
    'ones the user watched from it?',
    {
      for (final parent in _taxonomy.parents)
        // A category with no sub-categories to pick instead is left out.
        if (!(exclude?.parent == parent &&
            exclude?.child == null &&
            _taxonomy.childrenOf(parent).isEmpty))
          _key(parent): _describe(parent),
    },
  );

  /// Jev's pick: a category, from [parentAnswer] when already asked, then a
  /// sub-category within it, leaving [exclude] out; null when it gave none.
  Future<_Pick?> _jevPick(
    JevAccess jev,
    Object state,
    JevAnswer? parentAnswer, {
    CategoryPath? exclude,
  }) async {
    final parents = {
      for (final parent in _taxonomy.parents) _key(parent): parent,
    };
    parentAnswer ??= (await _askJev(jev, state, {
      'parent': _parentQuestion(exclude: exclude),
    }))['parent'];
    if (parentAnswer is! ChoiceAnswer) return null;
    final parent = parents[parentAnswer.choice];
    if (parent == null) return null;
    final parentOdds =
        parentAnswer.probabilities[parentAnswer.choice] ??
        parentAnswer.confidence;
    final otherParents = [
      for (final MapEntry(:key, :value) in parentAnswer.probabilities.entries)
        if (key != parentAnswer.choice && parents[key] != null)
          ScoredPath(path: CategoryPath(parents[key]!), score: value),
    ]..sort((a, b) => b.score.compareTo(a.score));

    final children = {
      for (final child in _taxonomy.childrenOf(parent))
        if (!(exclude?.parent == parent && exclude?.child == child))
          _key(child): child,
    };
    if (children.isEmpty) {
      return (
        path: CategoryPath(parent),
        score: parentOdds,
        runnersUp: otherParents.take(3).toList(),
      );
    }
    final childAnswer = (await _askJev(jev, state, {
      'child': JevChoice(
        'Which kind of $parent best describes the videos this channel makes '
        'and the ones the user watched from it?',
        {
          ...children,
          if (!(exclude?.parent == parent && exclude?.child == null))
            _general: 'None of these; just $parent in general',
        },
      ),
    }))['child'];
    if (childAnswer is! ChoiceAnswer) return null;
    double score(double childOdds) => sqrt(parentOdds * childOdds);
    CategoryPath? pathOf(String key) => key == _general
        ? CategoryPath(parent)
        : children[key] == null
        ? null
        : CategoryPath(parent, children[key]);
    final pick = pathOf(childAnswer.choice);
    if (pick == null) return null;
    final runnersUp = [
      for (final MapEntry(:key, :value) in childAnswer.probabilities.entries)
        if (key != childAnswer.choice)
          if (pathOf(key) case final path?)
            ScoredPath(path: path, score: score(value)),
      ...otherParents.take(1),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return (
      path: pick,
      score: score(
        childAnswer.probabilities[childAnswer.choice] ?? childAnswer.confidence,
      ),
      runnersUp: runnersUp.take(3).toList(),
    );
  }

  /// Claude's category: a sub-category there is, whatever its case; else one
  /// Jev finds is there already under another name; else a new one, kept.
  Future<ChannelCategory> _claudeCategory(
    ChannelInput input, {
    double? jevAgreed,
    CategoryPath? inaccurate,
  }) async {
    final claude = this.claude!;
    final request = claudeCategoryRequest(
      input.evidence,
      _taxonomy,
      inaccurate: inaccurate,
    );
    final Map<String, Object?> answer;
    try {
      answer = await claude.repository.structured(
        apiKey: claude.apiKey,
        model: claude.model,
        system: request.system,
        user: request.user,
        schema: request.schema,
      );
    } on AiFailure catch (e) {
      throw AiTierFailure(AiService.claude, e);
    }
    final suggestion = parseClaudeSuggestion(answer, _taxonomy);
    if (suggestion == null) {
      throw const AiTierFailure(AiService.claude, AiNoAnswer());
    }
    final (:parent, :child, :reason) = suggestion;
    final path = child == null
        ? CategoryPath(parent)
        : _taxonomy.find(parent, child) ??
              await _sameAsOneThere(input, parent, child, reason) ??
              _learn(parent, child);
    return _result(
      input,
      path: path,
      source: CategorySource.claude,
      jevAgreed: jevAgreed,
      reason: reason.isEmpty ? null : reason,
    );
  }

  /// The sub-category of [parent] Jev finds [child] is another name for, or
  /// null without Jev, or when it's new.
  Future<CategoryPath?> _sameAsOneThere(
    ChannelInput input,
    String parent,
    String child,
    String reason,
  ) async {
    final jev = this.jev;
    final existing = {for (final c in _taxonomy.childrenOf(parent)) _key(c): c};
    if (jev == null || existing.isEmpty) return null;
    final answer = (await _askJev(
      jev,
      {
        'proposed_sub_category': child,
        'category': parent,
        'why': reason,
        'channel': input.evidence.title,
      },
      {
        'same': JevChoice(
          'Is the proposed sub-category of $parent the same as one of these, '
          'under another name?',
          {...existing, _general: 'None of these; it is a different one'},
        ),
      },
    ))['same'];
    if (answer is! ChoiceAnswer || answer.choice == _general) return null;
    final match = existing[answer.choice];
    final odds = answer.probabilities[answer.choice] ?? answer.confidence;
    return match == null || odds < jevThreshold
        ? null
        : CategoryPath(parent, match);
  }

  /// Adds [child] under [parent] for later channels, or, when [parent] has
  /// as many as it takes, settles for [parent].
  CategoryPath _learn(String parent, String child) {
    if (_taxonomy.childrenOf(parent).length >= _maxChildren) {
      return CategoryPath(parent);
    }
    final path = CategoryPath(parent, child);
    _taxonomy = _taxonomy.withCustom({
      parent: [child],
    });
    _learned.add(path);
    return path;
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
    final children = _taxonomy.childrenOf(parent);
    return children.isEmpty ? parent : '$parent: ${children.join(', ')}';
  }

  /// An option key for [name]: Jev reads keys, so they say what they are.
  static String _key(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
}
