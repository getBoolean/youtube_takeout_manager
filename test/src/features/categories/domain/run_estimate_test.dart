import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/categorization_plan.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/run_estimate.dart';

WorkPlan _plan(ChannelWork work, {bool redo = false, bool checkTags = false}) =>
    (work: work, redo: redo, checkTags: checkTags);

final _uncategorized = ChannelCategory(decidedAt: DateTime.utc(2026, 10, 1));
final _categorized = ChannelCategory(
  path: const CategoryPath('Gaming'),
  decidedAt: DateTime.utc(2026, 10, 1),
);

const _both = AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-1');

void main() {
  test('a run is counted by what it does for each channel', () {
    final summary = summarizeWork([
      (plan: _plan(ChannelWork.categorize), existing: null, evidenceChars: 900),
      (
        plan: _plan(ChannelWork.categorize, redo: true),
        existing: _categorized,
        evidenceChars: 900,
      ),
      (
        plan: _plan(ChannelWork.tags),
        existing: _categorized,
        evidenceChars: 900,
      ),
      (
        plan: _plan(ChannelWork.claudeTags),
        existing: _categorized,
        evidenceChars: 900,
      ),
      (
        plan: _plan(ChannelWork.none, checkTags: true),
        existing: _uncategorized,
        evidenceChars: 900,
      ),
      (
        plan: _plan(ChannelWork.none),
        existing: _uncategorized,
        evidenceChars: 0,
      ),
    ]);

    expect(summary.categorize, 1);
    expect(summary.redo, 1);
    expect(summary.tags, 2);
    expect(summary.checks, 1);
    expect(summary.uncategorized, 2);
    expect(summary.hasWork, isTrue);
  });

  test('a run with nothing to do has no work', () {
    expect(
      summarizeWork([
        (
          plan: _plan(ChannelWork.none),
          existing: _categorized,
          evidenceChars: 0,
        ),
      ]).hasWork,
      isFalse,
    );
  });

  group('what a run costs', () {
    final summary = summarizeWork([
      for (var i = 0; i < 100; i++)
        (
          plan: _plan(ChannelWork.categorize),
          existing: null,
          evidenceChars: 2000,
        ),
    ]);

    test('in dollars for Jev, and for Claude on its usual model', () {
      final cost = estimateRunCost(
        summary,
        keys: _both,
        model: defaultAnthropicModel,
      );

      expect(cost.jevDollars, greaterThan(0));
      expect(cost.claudeDollars, greaterThan(cost.jevDollars));
      expect(cost.claudeRequests, 5);
    });

    test('with only Jev, nothing for Claude', () {
      final cost = estimateRunCost(
        summary,
        keys: const AiKeys(typesafe: 'jv_live_1'),
        model: defaultAnthropicModel,
      );

      expect(cost.jevDollars, greaterThan(0));
      expect(cost.claudeDollars, isNull);
      expect(cost.claudeRequests, 0);
    });

    test('in requests, not dollars, for Claude on another model', () {
      final cost = estimateRunCost(
        summary,
        keys: _both,
        model: 'claude-sonnet-5-5',
      );

      expect(cost.claudeDollars, isNull);
      expect(cost.claudeRequests, 5);
    });
  });

  test("a heavy viewer's 12,660 channels cost about \$2 with Jev and at "
      'most about \$13 with Claude', () {
    final summary = summarizeWork([
      for (var i = 0; i < 12660; i++)
        (
          plan: _plan(ChannelWork.categorize),
          existing: null,
          // Most channels have a video or two; a few have dozens.
          evidenceChars: i < 600 ? 8000 : 1500,
        ),
    ]);

    final cost = estimateRunCost(
      summary,
      keys: _both,
      model: defaultAnthropicModel,
    );

    expect(cost.jevDollars, inInclusiveRange(1, 4));
    expect(cost.claudeDollars, inInclusiveRange(9, 18));
  });
}
