import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/ai_result_merge.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';

ChannelCategory _category(
  String parent, {
  CategorySource source = CategorySource.youtube,
  UserDecision decision = UserDecision.none,
  List<String> tags = const [],
  bool tagsTried = false,
  bool edited = false,
}) => ChannelCategory(
  path: CategoryPath(parent),
  source: source,
  userDecision: decision,
  tags: tags,
  tagsTried: tagsTried,
  tagsEditedByUser: edited,
  decidedAt: DateTime.utc(2026, 10, 1),
);

void main() {
  final answer = _category(
    'Gaming',
    source: CategorySource.claude,
    tags: const ['Mario Kart World'],
    tagsTried: true,
  );

  test("a channel without a category takes the run's", () {
    expect(mergeAiResult(null, answer), answer);
  });

  test("an undecided category is replaced by the run's", () {
    final merged = mergeAiResult(_category('Music'), answer);

    expect(merged.path, const CategoryPath('Gaming'));
    expect(merged.tags, ['Mario Kart World']);
  });

  test('a category the user accepted, chose or kept stays, taking the '
      "run's tags", () {
    for (final existing in [
      _category('Music', decision: UserDecision.accepted),
      _category('Music', source: CategorySource.user),
      _category('Music', decision: UserDecision.denied),
    ]) {
      final merged = mergeAiResult(existing, answer);

      expect(merged.path, const CategoryPath('Music'));
      expect(merged.source, existing.source);
      expect(merged.userDecision, existing.userDecision);
      expect(merged.tags, ['Mario Kart World']);
      expect(merged.tagsTried, isTrue);
    }
  });

  test("tags the user edited stay, while the category takes the run's", () {
    final existing = _category(
      'Music',
      tags: const ['Jazz piano'],
      tagsTried: true,
      edited: true,
    );

    final merged = mergeAiResult(existing, answer);

    expect(merged.path, const CategoryPath('Gaming'));
    expect(merged.tags, ['Jazz piano']);
    expect(merged.tagsEditedByUser, isTrue);
  });

  test('a run that asked for no tags keeps the ones there were', () {
    final existing = _category(
      'Music',
      tags: const ['Jazz piano'],
      tagsTried: true,
    );

    final merged = mergeAiResult(
      existing,
      _category('Gaming', source: CategorySource.jev),
    );

    expect(merged.path, const CategoryPath('Gaming'));
    expect(merged.tags, ['Jazz piano']);
    expect(merged.tagsTried, isTrue);
  });
}
