import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/jev_prompts.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/prompt_fingerprints.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_prompts.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/prompt_videos.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_candidates.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';
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

  test("changing the wording of Claude's category instructions changes only "
      'its fingerprint', () {
    ClaudePart wordier(Taxonomy taxonomy) {
      final part = claudeCategoryPart(taxonomy);
      return (
        instructions: '${part.instructions} Be brief.',
        properties: part.properties,
      );
    }

    expect(_changed(PromptBuilders(claudeCategory: wordier)), {
      PromptStep.claudeCategory,
    });
  });

  test("changing Claude's tag instructions redoes tags, not categories", () {
    ClaudePart wordier(List<NamedTag> knownTags, {required bool found}) {
      final part = claudeTagsPart(knownTags, found: found);
      return (
        instructions: '${part.instructions} Prefer short tags.',
        properties: part.properties,
      );
    }

    expect(_changed(PromptBuilders(claudeTags: wordier)), {
      PromptStep.claudeTags,
    });
  });

  test("changing how channels are framed in a request to Claude changes "
      "Claude's steps alone; how many channels a request holds changes "
      'nothing', () {
    expect(_changed(PromptBuilders(claudeFraming: claudeFramingVersion + 1)), {
      PromptStep.claudeCategory,
      PromptStep.claudeTags,
    });
  });

  test("changing Jev's tag questions changes only their step", () {
    Map<String, JevQuestion> blunter(List<TagCandidate> candidates) => {
      ...jevTagQuestions(candidates),
      'other': const JevNoul('Anything else?'),
    };

    expect(_changed(PromptBuilders(jevTags: blunter)), {PromptStep.jevTags});
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
      PromptStep.jevTags,
      PromptStep.claudeCategory,
      PromptStep.claudeTags,
    });
  });

  test("changing one of Jev's category questions changes only its step", () {
    JevNoul blunter(CategoryPath candidate) =>
        JevNoul('Is "${candidate.label}" right?');

    expect(_changed(PromptBuilders(jevFit: blunter)), {PromptStep.jevCheck});
  });
}
