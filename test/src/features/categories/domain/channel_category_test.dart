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
