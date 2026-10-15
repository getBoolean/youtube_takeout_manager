import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import '../data/ai_errors.dart';
import '../data/ai_request.dart';
import '../data/anthropic_repository.dart';
import '../data/typesafe_repository.dart';
import '../domain/categorization_plan.dart';
import '../domain/category_path.dart';
import '../domain/category_prompts.dart';
import '../domain/channel_category.dart';
import '../domain/channel_evidence.dart';
import '../domain/model_capabilities.dart';
import '../domain/name_key.dart';
import '../domain/tag_candidates.dart';
import '../domain/tag_name.dart';
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

/// Requests about several channels Claude is sent at once; its pacer keeps
/// them within its limits too.
const _groupsAtOnce = 3;

/// The steps that decide a category, as opposed to tags.
const _categorySteps = {
  PromptStep.jevCheck,
  PromptStep.jevPick,
  PromptStep.jevNameCheck,
  PromptStep.claudeCategory,
};

/// What a channel needs from Claude: its category, with its tags, or its
/// tags alone.
enum ClaudeAsk { category, tags }

/// A channel left for Claude by [CategoryPipeline.prepare]: what's known
/// about it, what it needs, the category settled without Claude when only
/// its tags are wanted, the tags Jev kept with how sure it was, the steps
/// asked so far, how sure Jev was of YouTube's category, and a category the
/// user says is wrong.
class ClaudeTicket {
  final ChannelInput input;
  final ClaudeAsk ask;
  final ChannelCategory? settled;
  final List<(TagCandidate, double)> kept;
  final Set<PromptStep> asked;
  final double? jevAgreed;
  final CategoryPath? inaccurate;

  const ClaudeTicket._(
    this.input,
    this.ask, {
    this.settled,
    this.kept = const [],
    required this.asked,
    this.jevAgreed,
    this.inaccurate,
  });
}

/// What [CategoryPipeline.prepare] made of a channel.
sealed class Prepared {
  const Prepared();
}

/// Done without Claude: the channel's [result].
final class Settled extends Prepared {
  final ChannelCategory result;

  const Settled(this.result);
}

/// Waiting for Claude, as [ticket] says.
final class NeedsClaude extends Prepared {
  final ClaudeTicket ticket;

  const NeedsClaude(this.ticket);
}

/// Jev's check of the user's tags: how sure it is that each fits, by key,
/// as of the tags there were [at]; to apply to the channel's tags as they
/// are when it lands, the user's edits kept.
final class Checked extends Prepared {
  final Map<String, double> yes;
  final DateTime at;

  const Checked(this.yes, this.at);
}

/// Jev's pick: a category, how sure it is, and what came next.
typedef _Pick = ({CategoryPath path, double score, List<ScoredPath> runnersUp});

const _categorizing = (
  work: ChannelWork.categorize,
  redo: false,
  checkTags: false,
);
const _tagging = (work: ChannelWork.tags, redo: false, checkTags: false);

/// Categorizes channels in two phases, cheapest first.
///
/// [prepare] does what needs no Claude: YouTube's topics; with [jev], Jev's
/// check of them, then its own pick from [taxonomy]; then the channel's
/// tags from Jev, as Jev finds the tags there are fit. What's left for
/// Claude comes back as a ticket: a category Jev couldn't settle (or, without
/// Jev, one YouTube gives no sub-category for), or tags Jev found are
/// missing. [askClaude] asks Claude about many tickets at once, in groups. A
/// sub-category Claude names that [taxonomy] lacks joins it, unless Jev
/// finds it's one there already. Each result keeps the fingerprints of the
/// prompts that made it.
///
/// Throws an [AiTierFailure] naming the service when an AI step can't be
/// done, except for one with no usable answer for a channel: that channel
/// keeps what was settled, the step counted as tried.
class CategoryPipeline {
  Taxonomy _taxonomy;
  final Map<CategoryPath, int> _usage;
  final Map<PromptStep, String> _fingerprints;
  final JevAccess? jev;
  final ClaudeAccess? claude;
  final void Function(int inputTokens, int outputTokens)? _onUsage;
  final void Function(
    String key,
    int offered,
    Map<String, double> yes,
    double other,
  )?
  _onJevTags;
  final DateTime Function() _now;
  final _learned = <Learned>[];
  final _named = <NamedTag>[];

  /// Picks from [taxonomy]; [usage], how many channels have each category,
  /// decides which sub-categories Jev is offered when there are more than it
  /// takes. Results keep [fingerprints] of the prompts asked. [onUsage] is
  /// told the tokens each answer of Claude's used; [onJevTags], for each
  /// channel Jev is asked to tag, how many tags it was offered, how sure it
  /// is of each, by key, and that the channel is about something none of
  /// them name.
  CategoryPipeline({
    required Taxonomy taxonomy,
    Map<CategoryPath, int> usage = const {},
    Map<PromptStep, String>? fingerprints,
    this.jev,
    this.claude,
    void Function(int inputTokens, int outputTokens)? onUsage,
    void Function(
      String key,
      int offered,
      Map<String, double> yes,
      double other,
    )?
    onJevTags,
    DateTime Function()? now,
  }) : _taxonomy = taxonomy,
       _usage = usage,
       _fingerprints = fingerprints ?? currentPrompts,
       _onUsage = onUsage,
       _onJevTags = onJevTags,
       _now = now ?? DateTime.now;

  /// The categories it picks from, with the sub-categories Claude added.
  Taxonomy get taxonomy => _taxonomy;

  /// The sub-categories Claude added since last asked, to keep.
  List<Learned> takeLearned() {
    final learned = [..._learned];
    _learned.clear();
    return learned;
  }

  /// The tags Claude named since last asked, with their meanings, to keep.
  List<NamedTag> takeNamedTags() {
    final named = [..._named];
    _named.clear();
    return named;
  }

  /// The steps it takes.
  Set<CategorizationTier> get tiers => {
    CategorizationTier.youtube,
    if (jev != null) CategorizationTier.jev,
    if (claude != null) CategorizationTier.claude,
  };

  /// A channel's category as [asked] made it, with no tags yet.
  ChannelCategory _result(
    ChannelInput input,
    Set<PromptStep> asked, {
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
    prompts: {
      for (final step in asked)
        if (_categorySteps.contains(step)) step.name: _fingerprints[step]!,
    },
  );

  /// [base] with its tags: those Jev [kept], then those Claude [added], as
  /// [rankTags] orders them; waiting for Claude when [awaitClaude]. Claude's
  /// tags keep the tags prompt's fingerprint, whichever call named them.
  ChannelCategory _tagged(
    ChannelCategory base,
    Set<PromptStep> asked,
    TagIndex tags, {
    List<(TagCandidate, double)> kept = const [],
    List<String> added = const [],
    bool awaitClaude = false,
  }) => base.copyWith(
    tags: rankTags(kept, added, tags.names),
    tagsTried: true,
    tagsPrompt: null,
    tagsPrompts: {
      if (asked.contains(PromptStep.jevTags))
        PromptStep.jevTags.name: _fingerprints[PromptStep.jevTags]!,
      if (asked.contains(PromptStep.claudeTags) ||
          asked.contains(PromptStep.claudeCategory))
        PromptStep.claudeTags.name: _fingerprints[PromptStep.claudeTags]!,
    },
    tagsAwaitClaude: awaitClaude,
    tagsCheckedAt: tags.at,
  );

  /// What [plan] has done for the channel [input] tells of, whose category
  /// is [existing], without Claude: settled, left for Claude, or, for a
  /// check of the user's tags, Jev's answers. [tags] are the tags there are
  /// to offer.
  Future<Prepared> prepare(
    ChannelInput input,
    WorkPlan plan, {
    ChannelCategory? existing,
    required TagIndex tags,
  }) async {
    if (plan.work == ChannelWork.none) {
      return plan.checkTags
          ? _check(input, existing, tags)
          : Checked(const {}, tags.at);
    }
    final asked = <PromptStep>{};
    try {
      return switch (plan.work) {
        ChannelWork.categorize => await _settle(input, asked, tags),
        ChannelWork.tags => await _tagsOnto(input, existing!, asked, tags),
        ChannelWork.claudeTags => _awaitingClaude(input, existing!, tags),
        ChannelWork.none => throw StateError('Nothing to do'),
      };
    } on AiTierFailure catch (e) {
      if (e.failure is! AiNoAnswer) rethrow;
      // About this channel alone, such as a refusal, and paid for: asking
      // again would only pay again.
      return Settled(switch (plan.work) {
        ChannelWork.categorize => _tagged(
          _result(
            input,
            asked,
            path: youtubeCandidates(input.topicUrls).firstOrNull,
          ),
          asked,
          tags,
        ),
        _ => _tagged(existing!, asked, tags),
      });
    }
  }

  /// The category from YouTube and Jev, with its tags, or a ticket for
  /// Claude when they can't settle it.
  Future<Prepared> _settle(
    ChannelInput input,
    Set<PromptStep> asked,
    TagIndex tags,
  ) async {
    final candidates = youtubeCandidates(input.topicUrls);
    final jev = this.jev;
    if (jev == null) {
      // Without Jev to check it, YouTube's category stands; Claude only
      // names what YouTube gives no sub-category for.
      final youtube = candidates.firstOrNull;
      if (claude == null || youtube?.child != null) {
        return _tagsOnto(
          input,
          _result(input, asked, path: youtube),
          asked,
          tags,
        );
      }
      return NeedsClaude(
        ClaudeTicket._(input, ClaudeAsk.category, asked: asked),
      );
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
      return _tagsOnto(
        input,
        _result(input, asked, path: agreed, jevAgreed: agreement),
        asked,
        tags,
      );
    }

    final pick = await _jevPick(jev, state, answers['parent'], asked);
    if (pick != null && pick.score >= jevThreshold) {
      return _tagsOnto(
        input,
        _result(
          input,
          asked,
          path: pick.path,
          source: CategorySource.jev,
          jevAgreed: agreement,
          confidence: pick.score,
          runnersUp: pick.runnersUp,
        ),
        asked,
        tags,
      );
    }
    if (claude != null) {
      return NeedsClaude(
        ClaudeTicket._(
          input,
          ClaudeAsk.category,
          asked: asked,
          jevAgreed: agreement,
        ),
      );
    }
    return _tagsOnto(
      input,
      _result(input, asked, path: candidates.firstOrNull, jevAgreed: agreement),
      asked,
      tags,
    );
  }

  /// [base] with its tags from Jev: the tags it finds fit, of those [tags]
  /// offers for the channel; left for Claude when Jev finds it's about
  /// something no tag names, or there are none to offer. Without Claude,
  /// such a channel waits for it. A channel with no category gets none.
  Future<Prepared> _tagsOnto(
    ChannelInput input,
    ChannelCategory base,
    Set<PromptStep> asked,
    TagIndex tags,
  ) async {
    final path = base.path;
    final jev = this.jev;
    if (path == null || (jev == null && claude == null)) return Settled(base);
    final candidates = jev == null
        ? const <TagCandidate>[]
        : tags.candidatesFor(input.evidence, path);
    var kept = const <(TagCandidate, double)>[];
    // With nothing to offer Jev, Claude names them.
    var other = true;
    if (candidates.isNotEmpty) {
      asked.add(PromptStep.jevTags);
      final read = readJevTags(
        await _askJev(
          jev!,
          input.evidence.toState(),
          jevTagQuestions(candidates),
        ),
        candidates,
      );
      _onJevTags?.call(input.key, candidates.length, read.yes, read.other);
      kept = [
        for (final candidate in candidates)
          if (read.yes[candidate.key] case final yes? when yes >= jevThreshold)
            (candidate, yes),
      ];
      other = read.other >= otherThreshold;
    }
    final missing = other && kept.length < maxTags;
    if (missing && claude != null) {
      return NeedsClaude(
        ClaudeTicket._(
          input,
          ClaudeAsk.tags,
          settled: base,
          kept: kept,
          asked: asked,
        ),
      );
    }
    return Settled(
      _tagged(base, asked, tags, kept: kept, awaitClaude: missing),
    );
  }

  /// A ticket for Claude's tags for [existing], whose tags Jev found miss
  /// something; the tags it has stay first, in order.
  Prepared _awaitingClaude(
    ChannelInput input,
    ChannelCategory existing,
    TagIndex tags,
  ) => NeedsClaude(
    ClaudeTicket._(
      input,
      ClaudeAsk.tags,
      settled: existing,
      kept: [
        for (final (i, tag) in existing.tags.indexed)
          (
            (
              key: nameKey(tag),
              tag: tags.names[nameKey(tag)] ?? TagName(name: tag),
            ),
            1 - i / 100,
          ),
      ],
      asked: {
        if (existing.tagsPrompts.containsKey(PromptStep.jevTags.name))
          PromptStep.jevTags,
      },
    ),
  );

  /// Jev's check of the user's tags defined or changed since [existing]
  /// was last checked.
  Future<Prepared> _check(
    ChannelInput input,
    ChannelCategory? existing,
    TagIndex tags,
  ) async {
    final pending = tags.changedSince(existing?.tagsCheckedAt);
    final jev = this.jev;
    if (pending.isEmpty || jev == null) return Checked(const {}, tags.at);
    final questions = jevTagQuestions(pending)..remove('other');
    return Checked(
      readJevTags(
        await _askJev(jev, input.evidence.toState(), questions),
        pending,
      ).yes,
      tags.at,
    );
  }

  /// Asks Claude about [tickets], in groups of what fits one request, a
  /// few at once, and gives [onResult] each channel's result as its group
  /// is answered. Nothing more is sent once [stopped]. A group with no
  /// usable answer, or none in time, is asked again in halves, then one
  /// channel at a time; a
  /// channel a group's answer leaves out is asked again alone; one channel
  /// with no usable answer keeps what was settled, unless [noAnswerFails].
  /// Throws an [AiTierFailure] once the groups already sent are answered,
  /// when Claude can't be asked.
  Future<void> askClaude(
    List<ClaudeTicket> tickets, {
    required bool Function() stopped,
    required TagIndex tags,
    required FutureOr<void> Function(String key, ChannelCategory result)
    onResult,
    bool noAnswerFails = false,
  }) async {
    final claude = this.claude;
    if (claude == null || tickets.isEmpty) return;
    final groups = [
      for (final ask in ClaudeAsk.values)
        ...packGroups([
          for (final ticket in tickets)
            if (ticket.ask == ask) ticket,
        ], (ticket) => jsonEncode(ticket.input.evidence.toState()).length),
    ];
    var next = 0;
    AiTierFailure? failure;
    Future<void> worker() async {
      while (next < groups.length && failure == null && !stopped()) {
        try {
          await _askGroup(
            claude,
            groups[next++],
            stopped: stopped,
            tags: tags,
            onResult: onResult,
            noAnswerFails: noAnswerFails,
          );
        } on AiTierFailure catch (e) {
          failure ??= e;
        }
      }
    }

    await Future.wait([for (var i = 0; i < _groupsAtOnce; i++) worker()]);
    if (failure case final failure?) throw failure;
  }

  Future<void> _askGroup(
    ClaudeAccess claude,
    List<ClaudeTicket> group, {
    required bool Function() stopped,
    required TagIndex tags,
    required FutureOr<void> Function(String key, ChannelCategory result)
    onResult,
    required bool noAnswerFails,
  }) async {
    if (stopped()) return;
    Future<void> again(List<ClaudeTicket> part) => _askGroup(
      claude,
      part,
      stopped: stopped,
      tags: tags,
      onResult: onResult,
      noAnswerFails: noAnswerFails,
    );
    final byId = {for (final (i, ticket) in group.indexed) 'c${i + 1}': ticket};
    final withCategory = group.first.ask == ClaudeAsk.category;
    final items = [
      for (final MapEntry(key: id, value: ticket) in byId.entries)
        (
          id: id,
          evidence: ticket.input.evidence,
          category: ticket.settled?.path,
          keptTags: [
            for (final (candidate, _) in ticket.kept) candidate.tag.name,
          ],
          inaccurate: ticket.inaccurate,
        ),
    ];
    final known = tags.knownForClaude();
    final request = withCategory
        ? claudeCategoryGroupRequest(items, _taxonomy, knownTags: known)
        : claudeTagsGroupRequest(items, knownTags: known);
    final Map<String, Object?> answer;
    try {
      answer = await claude.repository.structured(
        apiKey: claude.apiKey,
        model: claude.model,
        system: request.system,
        user: request.user,
        schema: request.schema,
        maxTokens: groupAnswerTokens(
          group.length,
          withCategory: withCategory,
          modelMax: claude.model.maxTokens,
        ),
        expectedOutputTokens: group.length * (withCategory ? 120 : 60),
        onUsage: _onUsage,
        policy: RetryPolicy.claudeGroup,
      );
    } on AiFailure catch (e) {
      // Cut off, refused, or too long in coming (and maybe paid for, so not
      // asked again as it was): asked again in smaller parts, so one channel
      // doesn't cost the rest their answers.
      if (e is! AiNoAnswer && e is! AiTimedOut) {
        throw AiTierFailure(AiService.claude, e);
      }
      if (group.length == 1) {
        if (noAnswerFails) throw AiTierFailure(AiService.claude, e);
        await onResult(group.single.input.key, _noAnswer(group.single, tags));
        return;
      }
      final half = group.length ~/ 2;
      await again(group.sublist(0, half));
      await again(group.sublist(half));
      return;
    }

    final ids = byId.keys.toSet();
    final missing = <ClaudeTicket>[];
    if (withCategory) {
      final parsed = parseClaudeGroup(answer, ids, _taxonomy);
      for (final MapEntry(key: id, value: ticket) in byId.entries) {
        final suggestion = parsed[id];
        if (suggestion == null) {
          missing.add(ticket);
          continue;
        }
        await onResult(
          ticket.input.key,
          await _fromClaudeCategory(ticket, suggestion, tags),
        );
      }
    } else {
      final parsed = parseClaudeTagsGroup(answer, ids, {
        for (final MapEntry(key: id, value: ticket) in byId.entries)
          id: [for (final (candidate, _) in ticket.kept) candidate.tag.name],
      });
      for (final MapEntry(key: id, value: ticket) in byId.entries) {
        final named = parsed[id];
        if (named == null) {
          missing.add(ticket);
          continue;
        }
        _named.addAll(named);
        await onResult(
          ticket.input.key,
          _tagged(
            ticket.settled!,
            {...ticket.asked, PromptStep.claudeTags},
            tags,
            kept: ticket.kept,
            added: [for (final tag in named) tag.name],
          ),
        );
      }
    }
    for (final ticket in missing) {
      if (group.length > 1) {
        await again([ticket]);
      } else if (noAnswerFails) {
        throw const AiTierFailure(AiService.claude, AiNoAnswer());
      } else {
        await onResult(ticket.input.key, _noAnswer(ticket, tags));
      }
    }
  }

  /// A channel Claude gave no usable answer for: what was settled stands,
  /// Claude's step counted as asked, since it was paid for.
  ChannelCategory _noAnswer(ClaudeTicket ticket, TagIndex tags) {
    switch (ticket.ask) {
      case ClaudeAsk.category:
        final asked = {...ticket.asked, PromptStep.claudeCategory};
        return _tagged(
          _result(
            ticket.input,
            asked,
            path: youtubeCandidates(ticket.input.topicUrls).firstOrNull,
            jevAgreed: ticket.jevAgreed,
          ),
          asked,
          tags,
        );
      case ClaudeAsk.tags:
        return _tagged(
          ticket.settled!,
          {...ticket.asked, PromptStep.claudeTags},
          tags,
          kept: ticket.kept,
        );
    }
  }

  /// Claude's category and tags: a sub-category there is, whatever its
  /// case; else one Jev finds is there already under another name; else a
  /// new one, kept with its emoji.
  Future<ChannelCategory> _fromClaudeCategory(
    ClaudeTicket ticket,
    ClaudeSuggestion suggestion,
    TagIndex tags,
  ) async {
    final asked = {...ticket.asked, PromptStep.claudeCategory};
    final (:parent, :child, :emoji, tags: named, :reason) = suggestion;
    final path = child == null
        ? CategoryPath(parent)
        : _taxonomy.find(parent, child) ??
              await _sameAsOneThere(
                ticket.input,
                asked,
                parent,
                child,
                reason,
              ) ??
              _learn(parent, child, emoji);
    _named.addAll(named);
    return _tagged(
      _result(
        ticket.input,
        asked,
        path: path,
        source: CategorySource.claude,
        jevAgreed: ticket.jevAgreed,
        reason: reason.isEmpty ? null : reason,
      ),
      asked,
      tags,
      added: [for (final tag in named) tag.name],
    );
  }

  /// [input]'s category, with its tags, as one channel: [prepare], then
  /// Claude for it alone when it needs it. [tags] are the tags there are to
  /// offer; none when not given.
  Future<ChannelCategory> categorize(ChannelInput input, {TagIndex? tags}) =>
      _alone(input, _categorizing, null, tags);

  /// [current]'s tags alone, for its category, as one channel: Jev's, and
  /// Claude's for what they miss; with [fromClaude], Claude's added to the
  /// tags it has. Without a category, as it is.
  Future<ChannelCategory> retag(
    ChannelInput input,
    ChannelCategory current, {
    TagIndex? tags,
    bool fromClaude = false,
  }) => _alone(
    input,
    fromClaude
        ? (work: ChannelWork.claudeTags, redo: false, checkTags: false)
        : _tagging,
    current,
    tags,
  );

  Future<ChannelCategory> _alone(
    ChannelInput input,
    WorkPlan plan,
    ChannelCategory? existing,
    TagIndex? tags,
  ) async {
    final index = tags ?? TagIndex.of(const {}, const {}, at: _now());
    final prepared = await prepare(
      input,
      plan,
      existing: existing,
      tags: index,
    );
    switch (prepared) {
      case Settled(:final result):
        return result;
      case NeedsClaude(:final ticket):
        late ChannelCategory result;
        await askClaude(
          [ticket],
          stopped: () => false,
          tags: index,
          onResult: (_, answer) => result = answer,
        );
        return result;
      case Checked():
        throw StateError('A check is no category of its own');
    }
  }

  /// Another category than [current], for a channel the user says it's
  /// wrong for: Claude's, told so, with tags; else Jev's pick leaving
  /// [current] out. Throws an [AiTierFailure] when there's no usable
  /// answer.
  Future<ChannelCategory> suggestInstead(
    ChannelInput input,
    CategoryPath? current, {
    TagIndex? tags,
  }) async {
    final asked = <PromptStep>{};
    if (claude != null) {
      final index = tags ?? TagIndex.of(const {}, const {}, at: _now());
      late ChannelCategory result;
      await askClaude(
        [
          ClaudeTicket._(
            input,
            ClaudeAsk.category,
            asked: asked,
            inaccurate: current,
          ),
        ],
        stopped: () => false,
        tags: index,
        onResult: (_, answer) => result = answer,
        noAnswerFails: true,
      );
      return result;
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
