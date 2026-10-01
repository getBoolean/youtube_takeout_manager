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
import '../domain/name_key.dart';
import '../domain/youtube_taxonomy.dart';
import '../domain/youtube_topics.dart';
import 'ai_tiers.dart';
import 'jev_prompts.dart';
import 'prompt_fingerprints.dart';

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

/// A sub-category Claude named, with the emoji it gave it.
typedef Learned = ({CategoryPath path, String? emoji});

/// YouTube's categories Jev checks at most, of those a channel's topics
/// give.
const _maxChecked = 3;

/// Sub-categories a category takes at most, keeping Jev's choices under
/// its limit.
const _maxChildren = 200;

/// Sub-categories offered Jev at most, leaving room for [jevGeneral].
const _maxOffered = JevChoice.maxOptions - 1;

/// The steps that decide a category, as opposed to tags.
const _categorySteps = {
  PromptStep.jevCheck,
  PromptStep.jevPick,
  PromptStep.jevNameCheck,
  PromptStep.claudeCategory,
};

/// Jev's pick: a category, how sure it is, and what came next.
typedef _Pick = ({CategoryPath path, double score, List<ScoredPath> runnersUp});

/// Picks a channel's category, cheapest step first: YouTube's topics; with
/// [jev], Jev's check of them, then its own pick from [taxonomy]; and with
/// [claude], Claude, only when Jev can't settle it (or, without Jev, when
/// YouTube gives no sub-category). A sub-category Claude names that
/// [taxonomy] lacks joins it, unless Jev finds it's one there already.
///
/// With Claude, every channel gets one Claude call: the category and its
/// tags together when Claude names the category, else its tags alone. Each
/// result keeps the fingerprints of the prompts that made it.
///
/// Throws an [AiTierFailure] naming the service when an AI step can't be
/// done, except for one with no usable answer for the channel: that
/// channel keeps YouTube's category, the step counted as tried.
class CategoryPipeline {
  Taxonomy _taxonomy;
  final Map<CategoryPath, int> _usage;
  final List<String> _knownTags;
  final Map<String, String> _tagSpellings;
  final Map<PromptStep, String> _fingerprints;
  final JevAccess? jev;
  final ClaudeAccess? claude;
  final DateTime Function() _now;
  final _learned = <Learned>[];

  /// Picks from [taxonomy]; [usage], how many channels have each category,
  /// decides which sub-categories Jev is offered when there are more than it
  /// takes. Claude is told [knownTags] to reuse, and a tag it names is
  /// spelled as [tagSpellings] has it (by `nameKey`). Results keep
  /// [fingerprints] of the prompts asked.
  CategoryPipeline({
    required Taxonomy taxonomy,
    Map<CategoryPath, int> usage = const {},
    List<String> knownTags = const [],
    Map<String, String> tagSpellings = const {},
    Map<PromptStep, String>? fingerprints,
    this.jev,
    this.claude,
    DateTime Function()? now,
  }) : _taxonomy = taxonomy,
       _usage = usage,
       _knownTags = knownTags,
       _tagSpellings = tagSpellings,
       _fingerprints = fingerprints ?? currentPrompts,
       _now = now ?? DateTime.now;

  /// The categories it picks from, with the sub-categories Claude added.
  Taxonomy get taxonomy => _taxonomy;

  /// The sub-categories Claude added since last asked, to keep.
  List<Learned> takeLearned() {
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
    ChannelInput input,
    Set<PromptStep> asked, {
    CategoryPath? path,
    CategorySource source = CategorySource.youtube,
    double? jevAgreed,
    double? confidence,
    List<ScoredPath> runnersUp = const [],
    String? reason,
    List<String> tags = const [],
  }) {
    final tagsStep = asked.contains(PromptStep.claudeCategory)
        ? PromptStep.claudeCategory
        : asked.contains(PromptStep.claudeTags)
        ? PromptStep.claudeTags
        : null;
    return ChannelCategory(
      path: path,
      source: source,
      jevAgreed: jevAgreed,
      confidence: confidence,
      runnersUp: runnersUp,
      reason: reason,
      tried: tiers,
      hadTopics: input.topicUrls.isNotEmpty,
      decidedAt: _now().toUtc(),
      tags: tags,
      tagsTried: tagsStep != null,
      tagsPrompt: tagsStep == null ? null : _fingerprints[tagsStep],
      prompts: {
        for (final step in asked)
          if (_categorySteps.contains(step)) step.name: _fingerprints[step]!,
      },
    );
  }

  Future<ChannelCategory> categorize(ChannelInput input) async {
    final asked = <PromptStep>{};
    try {
      return await _categorize(input, asked);
    } on AiTierFailure catch (e) {
      if (e.failure is! AiNoAnswer) rethrow;
      // About this channel alone, such as a refusal, and paid for: asking
      // again would only pay again.
      return _result(
        input,
        asked,
        path: youtubeCandidates(input.topicUrls).firstOrNull,
      );
    }
  }

  /// [current]'s tags alone, from Claude, for its category: none when it
  /// gave no usable answer, still counted as tried. Without Claude, as it
  /// is.
  Future<ChannelCategory> retag(
    ChannelInput input,
    ChannelCategory current,
  ) async {
    final claude = this.claude;
    final path = current.path;
    if (claude == null) return current;
    final tagged = path == null
        ? const <String>[]
        : await _tagsOnly(claude, input, path);
    return current.copyWith(
      tags: tagged,
      tagsTried: true,
      tagsPrompt: _fingerprints[PromptStep.claudeTags],
    );
  }

  Future<ChannelCategory> _categorize(
    ChannelInput input,
    Set<PromptStep> asked,
  ) async {
    final candidates = youtubeCandidates(input.topicUrls);
    final jev = this.jev;
    if (jev == null) {
      // Without Jev to check it, YouTube's category stands; Claude only
      // names what YouTube gives no sub-category for.
      final youtube = candidates.firstOrNull;
      if (claude == null || youtube?.child != null) {
        return _withTags(input, asked, path: youtube);
      }
      return _claudeCategory(input, asked);
    }

    final state = input.evidence.toState();
    final checked = candidates.take(_maxChecked).toList();
    asked.add(PromptStep.jevCheck);
    final answers = await _askJev(jev, state, {
      for (final (i, candidate) in checked.indexed)
        'fits_$i': jevFitQuestion(candidate),
      'parent': jevParentQuestion(_taxonomy),
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
      return _withTags(input, asked, path: agreed, jevAgreed: agreement);
    }

    final pick = await _jevPick(jev, state, answers['parent'], asked);
    if (pick != null && pick.score >= jevThreshold) {
      return _withTags(
        input,
        asked,
        path: pick.path,
        source: CategorySource.jev,
        jevAgreed: agreement,
        confidence: pick.score,
        runnersUp: pick.runnersUp,
      );
    }
    if (claude != null) {
      return _claudeCategory(input, asked, jevAgreed: agreement);
    }
    return _result(
      input,
      asked,
      path: candidates.firstOrNull,
      jevAgreed: agreement,
    );
  }

  /// The result settled without Claude naming the category, with Claude's
  /// tags for it when Claude is there.
  Future<ChannelCategory> _withTags(
    ChannelInput input,
    Set<PromptStep> asked, {
    CategoryPath? path,
    CategorySource source = CategorySource.youtube,
    double? jevAgreed,
    double? confidence,
    List<ScoredPath> runnersUp = const [],
  }) async {
    final claude = this.claude;
    var tags = const <String>[];
    if (claude != null && path != null) {
      asked.add(PromptStep.claudeTags);
      tags = await _tagsOnly(claude, input, path);
    }
    return _result(
      input,
      asked,
      path: path,
      source: source,
      jevAgreed: jevAgreed,
      confidence: confidence,
      runnersUp: runnersUp,
      tags: tags,
    );
  }

  /// Claude's tags for a channel in [path]; none when it gave no usable
  /// answer.
  Future<List<String>> _tagsOnly(
    ClaudeAccess claude,
    ChannelInput input,
    CategoryPath path,
  ) async {
    final request = claudeTagsRequest(
      input.evidence,
      path,
      knownTags: _knownTags,
    );
    try {
      final answer = await claude.repository.structured(
        apiKey: claude.apiKey,
        model: claude.model,
        system: request.system,
        user: request.user,
        schema: request.schema,
      );
      return _spelled(parseClaudeTags(answer['tags']));
    } on AiNoAnswer {
      // About this channel alone, and paid for: not asked again.
      return const [];
    } on AiFailure catch (e) {
      throw AiTierFailure(AiService.claude, e);
    }
  }

  /// [tags] as the tags there are spell them, each once.
  List<String> _spelled(List<String> tags) {
    final keys = <String>{};
    return [
      for (final tag in tags)
        if (keys.add(nameKey(tag))) _tagSpellings[nameKey(tag)] ?? tag,
    ];
  }

  /// Another category than [current], for a channel the user says it's
  /// wrong for: Claude's, told so, with tags; else Jev's pick leaving
  /// [current] out.
  Future<ChannelCategory> suggestInstead(
    ChannelInput input,
    CategoryPath? current,
  ) async {
    final asked = <PromptStep>{};
    if (claude != null) {
      return _claudeCategory(input, asked, inaccurate: current);
    }
    final jev = this.jev;
    if (jev == null) throw StateError('No AI to ask');
    final pick = await _jevPick(
      jev,
      input.evidence.toState(),
      null,
      asked,
      exclude: current,
    );
    if (pick == null) throw const AiTierFailure(AiService.jev, AiNoAnswer());
    return _result(
      input,
      asked,
      path: pick.path,
      source: CategorySource.jev,
      confidence: pick.score,
      runnersUp: pick.runnersUp,
    );
  }

  /// The categories as Jev's options, by key: the same keys each time.
  Map<String, String> get _parentOptions => jevOptionKeys(_taxonomy.parents);

  /// Jev's pick: a category, from [parentAnswer] when already asked, then a
  /// sub-category within it, leaving [exclude] out; null when it gave none.
  Future<_Pick?> _jevPick(
    JevAccess jev,
    Object state,
    JevAnswer? parentAnswer,
    Set<PromptStep> asked, {
    CategoryPath? exclude,
  }) async {
    final parents = _parentOptions;
    asked.add(PromptStep.jevPick);
    parentAnswer ??= (await _askJev(jev, state, {
      'parent': jevParentQuestion(_taxonomy, exclude: exclude),
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

    final children = jevOptionKeys(
      _offered(
        parent,
        except: exclude?.parent == parent ? exclude?.child : null,
      ),
    );
    if (children.isEmpty) {
      return (
        path: CategoryPath(parent),
        score: parentOdds,
        runnersUp: otherParents.take(3).toList(),
      );
    }
    final childAnswer = (await _askJev(jev, state, {
      'child': jevChildQuestion(
        parent,
        children,
        withGeneral: !(exclude?.parent == parent && exclude?.child == null),
      ),
    }))['child'];
    if (childAnswer is! ChoiceAnswer) return null;
    double score(double childOdds) => sqrt(parentOdds * childOdds);
    CategoryPath? pathOf(String key) => key == jevGeneral
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

  /// Claude's category and tags: a sub-category there is, whatever its
  /// case; else one Jev finds is there already under another name; else a
  /// new one, kept with its emoji.
  Future<ChannelCategory> _claudeCategory(
    ChannelInput input,
    Set<PromptStep> asked, {
    double? jevAgreed,
    CategoryPath? inaccurate,
  }) async {
    final claude = this.claude!;
    final request = claudeCategoryRequest(
      input.evidence,
      _taxonomy,
      knownTags: _knownTags,
      inaccurate: inaccurate,
    );
    asked.add(PromptStep.claudeCategory);
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
    final (:parent, :child, :emoji, :tags, :reason) = suggestion;
    final path = child == null
        ? CategoryPath(parent)
        : _taxonomy.find(parent, child) ??
              await _sameAsOneThere(input, asked, parent, child, reason) ??
              _learn(parent, child, emoji);
    return _result(
      input,
      asked,
      path: path,
      source: CategorySource.claude,
      jevAgreed: jevAgreed,
      reason: reason.isEmpty ? null : reason,
      tags: _spelled(tags),
    );
  }

  /// The sub-category of [parent] Jev finds [child] is another name for, or
  /// null without Jev, or when it's new.
  Future<CategoryPath?> _sameAsOneThere(
    ChannelInput input,
    Set<PromptStep> asked,
    String parent,
    String child,
    String reason,
  ) async {
    final jev = this.jev;
    final existing = jevOptionKeys(_offered(parent));
    if (jev == null || existing.isEmpty) return null;
    asked.add(PromptStep.jevNameCheck);
    final answer = (await _askJev(
      jev,
      jevSameState(
        proposed: child,
        parent: parent,
        reason: reason,
        channel: input.evidence.title,
      ),
      {'same': jevSameQuestion(parent, existing)},
    ))['same'];
    if (answer is! ChoiceAnswer || answer.choice == jevGeneral) return null;
    final match = existing[answer.choice];
    final odds = answer.probabilities[answer.choice] ?? answer.confidence;
    return match == null || odds < jevThreshold
        ? null
        : CategoryPath(parent, match);
  }

  /// Adds [child] under [parent], with its [emoji], for later channels, or,
  /// when [parent] has as many as it takes, settles for [parent].
  CategoryPath _learn(String parent, String child, String? emoji) {
    if (_taxonomy.childrenOf(parent).length >= _maxChildren) {
      return CategoryPath(parent);
    }
    final path = CategoryPath(parent, child);
    _taxonomy = _taxonomy.withCustom({
      parent: [child],
    });
    _learned.add((path: path, emoji: emoji));
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

  /// [parent]'s sub-categories to offer Jev, leaving [except] out: all of
  /// them, or, when there are more than it takes, the most used, in their
  /// order, ties going to the first.
  List<String> _offered(String parent, {String? except}) {
    final children = [
      for (final child in _taxonomy.childrenOf(parent))
        if (child != except) child,
    ];
    if (children.length <= _maxOffered) return children;
    int used(String child) => _usage[CategoryPath(parent, child)] ?? 0;
    final ranked = [for (final (i, child) in children.indexed) (i, child)]
      ..sort((a, b) {
        final byUse = used(b.$2).compareTo(used(a.$2));
        return byUse != 0 ? byUse : a.$1.compareTo(b.$1);
      });
    final kept = {for (final (_, child) in ranked.take(_maxOffered)) child};
    return [
      for (final child in children)
        if (kept.contains(child)) child,
    ];
  }
}
