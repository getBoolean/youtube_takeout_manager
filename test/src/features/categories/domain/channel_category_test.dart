import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';

ChannelCategory _category({
  CategoryPath? path = const CategoryPath('Gaming', 'Action'),
  CategorySource source = CategorySource.youtube,
  double? jevAgreed,
  Set<CategorizationTier> tried = const {CategorizationTier.youtube},
  bool hadTopics = true,
  UserDecision userDecision = UserDecision.none,
}) => ChannelCategory(
  path: path,
  source: source,
  jevAgreed: jevAgreed,
  tried: tried,
  hadTopics: hadTopics,
  userDecision: userDecision,
  decidedAt: DateTime.utc(2026, 9, 30),
);

void main() {
  test('only Jev and Claude categories are AI ones', () {
    expect(_category().isAi, isFalse);
    expect(_category(source: CategorySource.jev).isAi, isTrue);
    expect(_category(source: CategorySource.claude).isAi, isTrue);
  });

  test('a category is kept and read back the same, however much it has', () {
    final full = ChannelCategory(
      path: const CategoryPath('Gaming', 'Speedruns'),
      source: CategorySource.claude,
      jevAgreed: 0.4,
      confidence: 0.9,
      runnersUp: const [
        ScoredPath(path: CategoryPath('Gaming', 'Action'), score: 0.1),
      ],
      reason: 'Races through games',
      tried: const {CategorizationTier.youtube, CategorizationTier.claude},
      hadTopics: true,
      userDecision: UserDecision.accepted,
      decidedAt: DateTime.utc(2026, 9, 30, 12),
    );

    for (final category in [full, _category(path: null)]) {
      expect(ChannelCategoryMapper.fromJson(category.toJson()), category);
    }
  });

  test('tags, who chose it and the prompts used are kept and read back', () {
    final tagged = ChannelCategory(
      path: const CategoryPath('Gaming', 'Racing'),
      source: CategorySource.user,
      tags: const ['Mario Kart World', 'Speedruns'],
      tagsTried: true,
      tagsEditedByUser: true,
      prompts: const {'jevCheck': 'ab12', 'claudeCategory': 'cd34'},
      tagsPrompt: 'ef56',
      decidedAt: DateTime.utc(2026, 10, 1),
    );

    expect(ChannelCategoryMapper.fromJson(tagged.toJson()), tagged);
  });

  test('a category saved before tags reads with none, not asked for, not '
      'edited, and no prompts', () {
    final category = ChannelCategoryMapper.fromMap({
      'path': {'parent': 'Music', 'child': 'Jazz'},
      'source': 'claude',
      'decidedAt': '2026-09-30T00:00:00.000Z',
    });

    expect(category.tags, isEmpty);
    expect(category.tagsTried, isFalse);
    expect(category.tagsEditedByUser, isFalse);
    expect(category.prompts, isEmpty);
    expect(category.tagsPrompt, isNull);
  });

  test('what is known about its tags is kept and read back: the prompts '
      'that made them, whether they wait for Claude, when they were last '
      'checked, and what the user added and removed', () {
    final tagged = ChannelCategory(
      path: const CategoryPath('Entertainment'),
      tags: const ['VTuber', 'Phase Connect'],
      tagsTried: true,
      tagsEditedByUser: true,
      tagsPrompts: const {'jevTags': 'ab12', 'claudeTags': 'cd34'},
      tagsAwaitClaude: true,
      tagsCheckedAt: DateTime.utc(2026, 10, 6, 9),
      tagsAddedByUser: const {'phaseconnect'},
      tagsRemovedByUser: const {'gaming'},
      decidedAt: DateTime.utc(2026, 10, 6),
    );

    expect(ChannelCategoryMapper.fromJson(tagged.toJson()), tagged);
  });

  test('a category saved with tags before they were checked or edited one '
      'by one reads with none of that', () {
    final category = ChannelCategoryMapper.fromMap({
      'path': {'parent': 'Gaming'},
      'source': 'claude',
      'tags': ['Speedruns'],
      'tagsTried': true,
      'tagsPrompt': 'fp',
      'decidedAt': '2026-10-01T00:00:00.000Z',
    });

    expect(category.tags, ['Speedruns']);
    expect(category.tagsPrompt, 'fp');
    expect(category.tagsPrompts, isEmpty);
    expect(category.tagsAwaitClaude, isFalse);
    expect(category.tagsCheckedAt, isNull);
    expect(category.tagsAddedByUser, isEmpty);
    expect(category.tagsRemovedByUser, isEmpty);
  });

  group('the tags AI may never take off', () {
    ChannelCategory tagged({
      bool edited = true,
      Set<String> added = const {},
      Set<String> removed = const {},
    }) => ChannelCategory(
      tags: const ['VTuber', 'ASMR'],
      tagsTried: true,
      tagsEditedByUser: edited,
      tagsAddedByUser: added,
      tagsRemovedByUser: removed,
      decidedAt: DateTime.utc(2026, 10, 6),
    );

    test('are the ones the user added', () {
      expect(tagged(added: const {'asmr'}).protectedTagKeys, {'asmr'});
      expect(tagged(removed: const {'gaming'}).protectedTagKeys, isEmpty);
    });

    test('are all of them on a channel the user edited before what they '
        'added was kept', () {
      expect(tagged().protectedTagKeys, {'vtuber', 'asmr'});
    });

    test("are none on a channel whose tags AI named", () {
      expect(tagged(edited: false).protectedTagKeys, isEmpty);
    });
  });

  test(
    "taking another's tags takes everything about them, and nothing else",
    () {
      final from = ChannelCategory(
        path: const CategoryPath('Music'),
        tags: const ['Cover Artist'],
        tagsTried: true,
        tagsEditedByUser: true,
        tagsPrompt: 'old',
        tagsPrompts: const {'jevTags': 'fp'},
        tagsAwaitClaude: true,
        tagsCheckedAt: DateTime.utc(2026, 10, 6),
        tagsAddedByUser: const {'coverartist'},
        tagsRemovedByUser: const {'music'},
        decidedAt: DateTime.utc(2026, 10, 6),
      );
      final category = _category();

      final taken = category.withTagsOf(from);

      expect(taken.path, category.path);
      expect(taken.decidedAt, category.decidedAt);
      expect(
        taken,
        from.copyWith(
          path: category.path,
          decidedAt: category.decidedAt,
          tried: category.tried,
          hadTopics: category.hadTopics,
        ),
      );
    },
  );

  test('a category the user chose, accepted or kept is decided', () {
    expect(_category().isDecided, isFalse);
    expect(_category(source: CategorySource.user).isDecided, isTrue);
    expect(_category(userDecision: UserDecision.accepted).isDecided, isTrue);
    expect(_category(userDecision: UserDecision.denied).isDecided, isTrue);
    expect(_category(source: CategorySource.user).isAi, isFalse);
  });

  test('a category saved by a newer version still reads', () {
    final category = ChannelCategoryMapper.fromMap({
      'path': {'parent': 'Music'},
      'source': 'someNewSource',
      'tried': ['youtube', 'someNewTier'],
      'userDecision': 'someNewDecision',
      'decidedAt': '2026-09-30T00:00:00.000Z',
    });

    expect(category.path, const CategoryPath('Music'));
    expect(category.userDecision, UserDecision.none);
  });
}
