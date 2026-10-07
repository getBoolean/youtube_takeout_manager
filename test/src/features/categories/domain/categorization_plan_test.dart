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
  'jevTags': 'jevtags-2',
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
  Map<String, String> tagsPrompts = const {},
  bool tagsAwaitClaude = false,
  DateTime? tagsCheckedAt,
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
  tagsPrompts: tagsPrompts,
  tagsAwaitClaude: tagsAwaitClaude,
  tagsCheckedAt: tagsCheckedAt,
  decidedAt: DateTime.utc(2026, 9, 30),
);

WorkPlan _plan(
  ChannelCategory? existing, {
  Set<CategorizationTier> available = _withBoth,
  bool hasTopics = true,
  DateTime? userTagsChangedAt,
}) => planWork(
  existing,
  available: available,
  hasTopics: hasTopics,
  fingerprints: _now,
  userTagsChangedAt: userTagsChangedAt,
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
          isNot(ChannelWork.categorize),
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
        isNot(ChannelWork.categorize),
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
            tagsPrompts: const {'claudeTags': 'tags-2'},
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
          tagsPrompts: const {'claudeTags': 'tags-2'},
        ),
      );

      expect(plan, (
        work: ChannelWork.categorize,
        redo: true,
        checkTags: false,
      ));
    });

    test('when an AI made it before prompts were kept', () {
      expect(
        _plan(_category(source: CategorySource.claude, tried: _withBoth)),
        (work: ChannelWork.categorize, redo: true, checkTags: false),
      );
      expect(_plan(_category(jevAgreed: 0.9, tried: _withBoth)), (
        work: ChannelWork.categorize,
        redo: true,
        checkTags: false,
      ));
    });

    test("not when YouTube's topics alone made it", () {
      expect(
        _work(
          _category(
            tried: _withBoth,
            tagsTried: true,
            tagsPrompts: const {'claudeTags': 'tags-2'},
          ),
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
            tagsPrompts: const {'claudeTags': 'tags-2'},
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
        expect(
          _work(claudes, available: _withJev),
          isNot(ChannelWork.categorize),
        );
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
        (work: ChannelWork.tags, redo: false, checkTags: false),
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
    test('when Jev or Claude is there and they were never asked for', () {
      for (final available in [_withClaude, _withJev]) {
        expect(
          _plan(
            _category(userDecision: UserDecision.accepted),
            available: available,
          ),
          (work: ChannelWork.tags, redo: false, checkTags: false),
          reason: '$available',
        );
      }
      expect(
        _work(
          _category(tried: _withBoth, prompts: const {}),
          available: _withClaude,
        ),
        ChannelWork.tags,
      );
    });

    test('never in a run that asks no AI, nor for a channel with no '
        'category', () {
      expect(
        _work(
          _category(userDecision: UserDecision.accepted),
          available: _youtubeOnly,
        ),
        ChannelWork.none,
      );
      expect(
        _work(
          _category(path: null, tried: _withBoth, hadTopics: false),
          hasTopics: false,
        ),
        ChannelWork.none,
      );
    });

    test('again when a prompt that made them has changed, once the AI that '
        'made them is there', () {
      final byJev = _category(
        source: CategorySource.user,
        tagsTried: true,
        tagsPrompts: const {'jevTags': 'jevtags-1'},
      );
      expect(_plan(byJev, available: _withJev), (
        work: ChannelWork.tags,
        redo: true,
        checkTags: false,
      ));
      expect(_work(byJev, available: _withClaude), ChannelWork.none);

      final byBoth = _category(
        source: CategorySource.user,
        tagsTried: true,
        tagsPrompts: const {'jevTags': 'jevtags-2', 'claudeTags': 'tags-1'},
      );
      expect(_work(byBoth), ChannelWork.tags);
      expect(_work(byBoth, available: _withJev), ChannelWork.none);
    });

    test('again, once, when named before prompts were kept for each step, '
        'while Claude, which named them, is there', () {
      final older = _category(
        source: CategorySource.user,
        tagsTried: true,
        tagsPrompt: 'tags-1',
      );

      expect(_plan(older, available: _withClaude), (
        work: ChannelWork.tags,
        redo: true,
        checkTags: false,
      ));
      expect(_work(older, available: _withJev), ChannelWork.none);
    });

    test('not when named by the prompts as they are now', () {
      for (final prompts in [
        const {'claudeTags': 'tags-2'},
        const {'jevTags': 'jevtags-2'},
        const {'jevTags': 'jevtags-2', 'claudeTags': 'tags-2'},
      ]) {
        expect(
          _work(
            _category(
              source: CategorySource.user,
              tagsTried: true,
              tagsPrompts: prompts,
            ),
          ),
          ChannelWork.none,
          reason: '$prompts',
        );
      }
    });

    test('from Claude, when Jev found the channel is about something no tag '
        'names and Claude is there now', () {
      final waiting = _category(
        source: CategorySource.user,
        tagsTried: true,
        tagsPrompts: const {'jevTags': 'jevtags-2'},
        tagsAwaitClaude: true,
      );

      expect(_plan(waiting, available: _withClaude), (
        work: ChannelWork.claudeTags,
        redo: false,
        checkTags: false,
      ));
      expect(_work(waiting, available: _withJev), ChannelWork.none);
    });

    test('never once the user edited them', () {
      for (final edited in [
        _category(
          source: CategorySource.user,
          tagsTried: true,
          tagsEdited: true,
          tagsPrompt: 'tags-1',
        ),
        _category(
          source: CategorySource.user,
          tagsTried: true,
          tagsEdited: true,
          tagsAwaitClaude: true,
        ),
      ]) {
        expect(_work(edited), ChannelWork.none);
      }
    });
  });

  group("a channel is checked for the user's tags", () {
    final checkedAt = DateTime.utc(2026, 10, 5);
    final after = DateTime.utc(2026, 10, 6);
    final done = _category(
      source: CategorySource.user,
      tagsTried: true,
      tagsPrompts: const {'jevTags': 'jevtags-2'},
      tagsCheckedAt: checkedAt,
    );

    test('when one was defined or changed after its last check, with Jev', () {
      expect(_plan(done, userTagsChangedAt: after), (
        work: ChannelWork.none,
        redo: false,
        checkTags: true,
      ));
      expect(_plan(done, userTagsChangedAt: checkedAt).checkTags, isFalse);
      expect(
        _plan(done, available: _withClaude, userTagsChangedAt: after).checkTags,
        isFalse,
      );
    });

    test('even when the user edited its tags, or it has no category', () {
      for (final channel in [
        _category(
          source: CategorySource.user,
          tagsTried: true,
          tagsEdited: true,
          tagsCheckedAt: checkedAt,
        ),
        _category(
          path: null,
          tried: _withBoth,
          hadTopics: false,
          tagsCheckedAt: checkedAt,
        ),
      ]) {
        expect(
          _plan(channel, hasTopics: false, userTagsChangedAt: after).checkTags,
          isTrue,
          reason: '$channel',
        );
      }
    });

    test("too when it waits for Claude's tags, which check none", () {
      final waiting = _category(
        source: CategorySource.user,
        tagsTried: true,
        tagsPrompts: const {'jevTags': 'jevtags-2'},
        tagsAwaitClaude: true,
        tagsCheckedAt: checkedAt,
      );

      expect(_plan(waiting, userTagsChangedAt: after), (
        work: ChannelWork.claudeTags,
        redo: false,
        checkTags: true,
      ));
      expect(_plan(waiting, userTagsChangedAt: checkedAt).checkTags, isFalse);
    });

    test('not when it is to be categorized or tagged, which offers every '
        'tag', () {
      final plan = _plan(
        _category(userDecision: UserDecision.accepted),
        userTagsChangedAt: after,
      );

      expect(plan.work, ChannelWork.tags);
      expect(plan.checkTags, isFalse);
    });

    test('not in a run that asks no AI', () {
      expect(
        _plan(
          done,
          available: _youtubeOnly,
          userTagsChangedAt: after,
        ).checkTags,
        isFalse,
      );
    });
  });
}
