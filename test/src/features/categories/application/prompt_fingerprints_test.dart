import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/prompt_fingerprints.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_prompts.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/prompt_videos.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';

/// The steps whose fingerprints [builders] changes.
Set<PromptStep> _changed(PromptBuilders builders) {
  final before = fingerprintPrompts();
  final after = fingerprintPrompts(builders);
  return {
    for (final step in PromptStep.values)
      if (before[step] != after[step]) step,
  };
}

void main() {
  test('the same prompts give the same fingerprints', () {
    expect(fingerprintPrompts(), fingerprintPrompts());
    expect(currentPrompts, fingerprintPrompts());
  });

  test('every step has a fingerprint of its own', () {
    expect(
      fingerprintPrompts().values.toSet(),
      hasLength(PromptStep.values.length),
    );
  });

  test("changing the wording of Claude's category prompt changes only its "
      'fingerprint', () {
    ClaudeRequest wordier(
      ChannelEvidence evidence,
      Taxonomy taxonomy, {
      List<String> knownTags = const [],
      CategoryPath? inaccurate,
    }) {
      final request = claudeCategoryRequest(
        evidence,
        taxonomy,
        knownTags: knownTags,
        inaccurate: inaccurate,
      );
      return (
        system: '${request.system} Be brief.',
        user: request.user,
        schema: request.schema,
      );
    }

    expect(_changed(PromptBuilders(claudeCategory: wordier)), {
      PromptStep.claudeCategory,
    });
  });

  test('changing how videos are picked changes every step told about '
      'them', () {
    List<PromptPicks> fewer(LoadedHistory loaded) => [
      for (final picks in pickPromptVideos(loaded))
        (
          titles: picks.titles.take(picks.titles.length - 1).toList(),
          described: picks.described,
        ),
    ];

    expect(_changed(PromptBuilders(pickVideos: fewer)), {
      PromptStep.jevCheck,
      PromptStep.jevPick,
      PromptStep.claudeCategory,
      PromptStep.claudeTags,
    });
  });

  test("changing one of Jev's questions changes only its step", () {
    JevNoul blunter(CategoryPath candidate) =>
        JevNoul('Is "${candidate.label}" right?');

    expect(_changed(PromptBuilders(jevFit: blunter)), {PromptStep.jevCheck});
  });
}
