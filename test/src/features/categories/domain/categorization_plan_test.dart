import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/categorization_plan.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';

const _youtubeOnly = {CategorizationTier.youtube};
const _withJev = {CategorizationTier.youtube, CategorizationTier.jev};
const _withClaude = {
  ...{CategorizationTier.youtube},
  CategorizationTier.claude,
};
const _withBoth = {..._withJev, CategorizationTier.claude};

/// The prompts as they are now, by step.
const _now = {
  'jevCheck': 'check-2',
  'jevPick': 'pick-2',
  'jevNameCheck': 'name-2',
  'claudeCategory': 'claude-2',
  'claudeTags': 'tags-2',
};

ChannelCategory _category({
  CategoryPath? path = const CategoryPath('Gaming', 'Action'),
  CategorySource source = CategorySource.youtube,
  double? jevAgreed,
  Set<CategorizationTier> tried = const {CategorizationTier.youtube},
  bool hadTopics = true,
  UserDecision userDecision = UserDecision.none,
  Map<String, String> prompts = const {},
  bool tagsTried = false,
  bool tagsEdited = false,
  String? tagsPrompt,
}) => ChannelCategory(
  path: path,
  source: source,
  jevAgreed: jevAgreed,
  tried: tried,
  hadTopics: hadTopics,
  userDecision: userDecision,
  prompts: prompts,
  tagsTried: tagsTried,
  tagsEditedByUser: tagsEdited,
  tagsPrompt: tagsPrompt,
  decidedAt: DateTime.utc(2026, 9, 30),
);

WorkPlan _plan(
  ChannelCategory? existing, {
  Set<CategorizationTier> available = _withBoth,
  bool hasTopics = true,
}) => planWork(
  existing,
  available: available,
  hasTopics: hasTopics,
  fingerprints: _now,
);

ChannelWork _work(
  ChannelCategory? existing, {
  Set<CategorizationTier> available = _withBoth,
  bool hasTopics = true,
}) => _plan(existing, available: available, hasTopics: hasTopics).work;

void main() {
  group('a channel is categorized', () {
    test('when it has none and its topics or an AI can give one', () {
      expect(
        _work(null, available: _youtubeOnly, hasTopics: true),
        ChannelWork.categorize,
      );
      expect(
        _work(null, available: _withJev, hasTopics: false),
        ChannelWork.categorize,
      );
    });

    test('not when nothing could give it one', () {
      expect(
        _work(null, available: _youtubeOnly, hasTopics: false),
        ChannelWork.none,
      );
    });

    test('never again once the user decided it', () {
      for (final decided in [
        _category(userDecision: UserDecision.accepted),
        _category(userDecision: UserDecision.denied),
        _category(source: CategorySource.user),
      ]) {
        expect(
          _work(decided, available: _withJev),
          ChannelWork.none,
          reason: '$decided',
        );
      }
    });

    test('again when it had none, once topics or a new AI are there', () {
      final none = _category(path: null, hadTopics: false);

      expect(
        _work(none, available: _youtubeOnly, hasTopics: true),
        ChannelWork.categorize,
      );
      expect(
        _work(none, available: _withJev, hasTopics: false),
        ChannelWork.categorize,
      );
      expect(
        _work(none, available: _youtubeOnly, hasTopics: false),
        ChannelWork.none,
      );
    });

    test("again for Jev's check, once Jev is there, for YouTube's pick", () {
      expect(_work(_category(), available: _withJev), ChannelWork.categorize);
      expect(
        _work(
          _category(
            tried: _withJev,
            jevAgreed: 0.9,
            prompts: const {'jevCheck': 'check-2'},
          ),
          available: _withJev,
        ),
        ChannelWork.none,
      );
      expect(_work(_category(), available: _youtubeOnly), ChannelWork.none);
    });

    test("again for Claude, once it is there, when Jev doubted YouTube's "
        'pick and had none better', () {
      expect(
        _work(
          _category(
            tried: _withJev,
            jevAgreed: 0.3,
            prompts: const {'jevCheck': 'check-2', 'jevPick': 'pick-2'},
          ),
        ),
        ChannelWork.categorize,
      );
    });

    test('not again for an AI pick made with the prompts there are', () {
      expect(
        _work(
          _category(
            source: CategorySource.claude,
            tried: _withBoth,
            prompts: const {'claudeCategory': 'claude-2'},
            tagsTried: true,
            tagsPrompt: 'claude-2',
          ),
        ),
        ChannelWork.none,
      );
    });
  });

  group('a channel is categorized again, as a redo,', () {
    test('when a prompt that made its category has changed', () {
      final plan = _plan(
        _category(
          source: CategorySource.jev,
          tried: _withBoth,
          prompts: const {'jevCheck': 'check-1', 'jevPick': 'pick-2'},
          tagsTried: true,
          tagsPrompt: 'tags-2',
        ),
      );

      expect(plan, (work: ChannelWork.categorize, redo: true));
    });

    test('when an AI made it before prompts were kept', () {
      expect(
        _plan(_category(source: CategorySource.claude, tried: _withBoth)),
        (work: ChannelWork.categorize, redo: true),
      );
      expect(_plan(_category(jevAgreed: 0.9, tried: _withBoth)), (
        work: ChannelWork.categorize,
        redo: true,
      ));
    });

    test("not when YouTube's topics alone made it", () {
      expect(
        _work(
          _category(tried: _withBoth, tagsTried: true, tagsPrompt: 'tags-2'),
          available: _withClaude,
        ),
        ChannelWork.none,
      );
    });

    test('not when the user decided it, whatever the prompts', () {
      expect(
        _work(
          _category(
            source: CategorySource.claude,
            userDecision: UserDecision.accepted,
            prompts: const {'claudeCategory': 'claude-1'},
            tagsTried: true,
            tagsPrompt: 'claude-2',
          ),
        ),
        ChannelWork.none,
      );
    });

    test("not while the AI that made it isn't there: Claude's, with only "
        'Jev', () {
      for (final claudes in [
        _category(source: CategorySource.claude, tried: _withBoth),
        _category(
          source: CategorySource.claude,
          tried: _withBoth,
          prompts: const {'claudeCategory': 'claude-1'},
        ),
      ]) {
        expect(_work(claudes, available: _withJev), ChannelWork.none);
      }
    });

    test("not while the AI that made it isn't there: Jev's check, with only "
        'Claude, which names its tags instead', () {
      expect(
        _plan(
          _category(
            jevAgreed: 0.9,
            tried: const {CategorizationTier.youtube, CategorizationTier.jev},
          ),
          available: _withClaude,
        ),
        (work: ChannelWork.tags, redo: false),
      );
    });

    test('not without an AI to redo it', () {
      expect(
        _work(
          _category(source: CategorySource.claude),
          available: _youtubeOnly,
        ),
        ChannelWork.none,
      );
    });
  });

  group("a channel's tags are asked for alone", () {
    test('when Claude is there and they were never asked for', () {
      expect(
        _plan(
          _category(userDecision: UserDecision.accepted),
          available: _withClaude,
        ),
        (work: ChannelWork.tags, redo: false),
      );
      expect(
        _work(
          _category(tried: _withBoth, prompts: const {}),
          available: _withClaude,
        ),
        ChannelWork.tags,
      );
    });

    test('again when the prompt that named them has changed', () {
      expect(
        _plan(
          _category(
            source: CategorySource.user,
            tagsTried: true,
            tagsPrompt: 'tags-1',
          ),
        ),
        (work: ChannelWork.tags, redo: true),
      );
    });

    test('not when named by either prompt as it is now', () {
      for (final prompt in ['tags-2', 'claude-2']) {
        expect(
          _work(
            _category(
              source: CategorySource.user,
              tagsTried: true,
              tagsPrompt: prompt,
            ),
          ),
          ChannelWork.none,
          reason: prompt,
        );
      }
    });

    test('never once the user edited them', () {
      expect(
        _work(
          _category(
            source: CategorySource.user,
            tagsTried: true,
            tagsEdited: true,
            tagsPrompt: 'tags-1',
          ),
        ),
        ChannelWork.none,
      );
    });

    test('not without Claude', () {
      expect(
        _work(
          _category(userDecision: UserDecision.accepted),
          available: _withJev,
        ),
        ChannelWork.none,
      );
    });
  });
}
