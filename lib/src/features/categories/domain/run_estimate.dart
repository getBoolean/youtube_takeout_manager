import 'package:youtube_takeout_manager/src/config/ai_config.dart';

import 'categorization_plan.dart';
import 'category_prompts.dart';
import 'channel_category.dart';

/// What a run with AI would do: channels to categorize for the first time,
/// to do again because a prompt changed, to tag, and to check for the tags
/// the user defined; channels it leaves without a category, which get no
/// tags; and
/// the size of the evidence of each channel AI would be told about.
class AiWorkSummary {
  final int categorize;
  final int redo;
  final int tags;
  final int checks;
  final int uncategorized;

  /// The characters of evidence, as JSON, of each channel to categorize or
  /// tag, the ones Claude may be told of.
  final List<int> evidenceChars;

  /// The same, of each channel to check.
  final List<int> checkChars;

  const AiWorkSummary({
    required this.categorize,
    required this.redo,
    required this.tags,
    required this.checks,
    required this.uncategorized,
    this.evidenceChars = const [],
    this.checkChars = const [],
  });

  /// Whether a run would do anything.
  bool get hasWork => categorize + redo + tags + checks > 0;
}

/// A channel as a run with AI would take it: what it would do, the
/// category it has, and how much evidence AI would be told.
typedef PlannedChannel = ({
  WorkPlan plan,
  ChannelCategory? existing,
  int evidenceChars,
});

/// What a run would do for [channels].
AiWorkSummary summarizeWork(Iterable<PlannedChannel> channels) {
  var categorize = 0;
  var redo = 0;
  var tags = 0;
  var checks = 0;
  var uncategorized = 0;
  final evidenceChars = <int>[];
  final checkChars = <int>[];
  for (final (:plan, :existing, evidenceChars: chars) in channels) {
    // Left without a category: the run won't try to give it one.
    if (existing != null &&
        existing.path == null &&
        plan.work != ChannelWork.categorize) {
      uncategorized++;
    }
    switch (plan.work) {
      case ChannelWork.none:
        if (plan.checkTags) {
          checks++;
          checkChars.add(chars);
        }
        continue;
      case _ when plan.redo:
        redo++;
      case ChannelWork.categorize:
        categorize++;
      case ChannelWork.tags || ChannelWork.claudeTags:
        tags++;
    }
    evidenceChars.add(chars);
  }
  return AiWorkSummary(
    categorize: categorize,
    redo: redo,
    tags: tags,
    checks: checks,
    uncategorized: uncategorized,
    evidenceChars: evidenceChars,
    checkChars: checkChars,
  );
}

/// What a run would cost: in dollars with Jev; in dollars with Claude on
/// its usual model, as if every channel reached it, and in requests.
typedef RunCost = ({
  double jevDollars,
  double? claudeDollars,
  int claudeRequests,
});

/// Jev's price per input token; its output is free.
const _jevPerToken = 0.042 / 1e6;

/// Claude Haiku's prices per token, in and out.
const _claudeInPerToken = 1 / 1e6;
const _claudeOutPerToken = 5 / 1e6;

/// About what one channel's answer from Claude is, in tokens.
const _claudeAnswerTokens = 100;

/// About what a request to Claude says besides its channels, in tokens.
const _claudeRequestTokens = 1500;

/// About what Jev's questions about a channel's tags are, in tokens.
const _jevTagQuestionTokens = 2500;

/// About what [summary]'s run costs with [keys], Claude being [model]:
/// Jev reads each channel's evidence about twice and a half (checking
/// YouTube's category, picking its own, then its tags) and once more for
/// each check; Claude, at most, every channel to categorize or tag, in
/// requests packed as a run packs them.
RunCost estimateRunCost(
  AiWorkSummary summary, {
  required AiKeys keys,
  required String model,
}) {
  int tokens(int chars) => chars ~/ 4;
  var jevTokens = 0;
  for (final chars in summary.evidenceChars) {
    jevTokens += (tokens(chars) * 2.5).round() + _jevTagQuestionTokens;
  }
  for (final chars in summary.checkChars) {
    jevTokens += tokens(chars) + 300;
  }
  if (!keys.hasClaude) {
    return (
      jevDollars: keys.hasJev ? jevTokens * _jevPerToken : 0,
      claudeDollars: null,
      claudeRequests: 0,
    );
  }
  final requests = packGroups(summary.evidenceChars, (chars) => chars).length;
  final claudeIn =
      summary.evidenceChars.fold(0, (sum, chars) => sum + tokens(chars)) +
      requests * _claudeRequestTokens;
  final claudeOut = summary.evidenceChars.length * _claudeAnswerTokens;
  return (
    jevDollars: keys.hasJev ? jevTokens * _jevPerToken : 0,
    claudeDollars: model == defaultAnthropicModel
        ? claudeIn * _claudeInPerToken + claudeOut * _claudeOutPerToken
        : null,
    claudeRequests: requests,
  );
}

/// What Claude's answers that used [input] and [output] tokens cost on its
/// usual model, in dollars.
double claudeDollars(int input, int output) =>
    input * _claudeInPerToken + output * _claudeOutPerToken;
