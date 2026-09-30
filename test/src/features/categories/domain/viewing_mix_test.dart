import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';

const _action = CategoryPath('Gaming', 'Action game');
const _puzzle = CategoryPath('Gaming', 'Puzzle game');
const _gaming = CategoryPath('Gaming');
const _cooking = CategoryPath('Lifestyle', 'Cooking');

/// Six channels: 5 + 3 + 2 videos of Gaming (one only known as Gaming),
/// 6 of Cooking, 4 uncategorized, and a Cooking one never watched.
final _categories = <String, CategoryPath?>{
  'a': _action,
  'b': _action,
  'p': _puzzle,
  'g': _gaming,
  'c': _cooking,
  'u': null,
  'never': _cooking,
};

List<CategoryShare> _mix() => computeViewingMix(
  channels: const [
    (key: 'a', count: 3),
    (key: 'b', count: 2),
    (key: 'p', count: 3),
    (key: 'g', count: 2),
    (key: 'c', count: 6),
    (key: 'u', count: 4),
    (key: 'never', count: 0),
  ],
  categoryOf: (key) => _categories[key],
);

String _row(CategoryShare s) =>
    '${s.pick.label}: ${s.watchCount} videos, ${s.channelCount} channels';

void main() {
  test('categories are listed largest first, with their shares of the '
      'watched videos adding up to all of them', () {
    final mix = _mix();

    expect(
      [for (final s in mix) _row(s)],
      [
        'Gaming: 10 videos, 4 channels',
        'Lifestyle: 6 videos, 2 channels',
        'Uncategorized: 4 videos, 1 channels',
      ],
    );
    expect(mix.fold(0.0, (sum, s) => sum + s.share), closeTo(1, 1e-9));
    expect(mix.first.share, closeTo(0.5, 1e-9));
  });

  test("sub-categories are under their category, largest first, and "
      "channels only known by the category have a row of their own", () {
    final gaming = _mix().first;

    expect(
      [for (final s in gaming.children) _row(s)],
      [
        'Gaming › Action game: 5 videos, 2 channels',
        'Gaming › Puzzle game: 3 videos, 1 channels',
        'Gaming (general): 2 videos, 1 channels',
      ],
    );
    expect(
      gaming.children.fold(0.0, (sum, s) => sum + s.share),
      closeTo(gaming.share, 1e-9),
    );
  });

  test('a category with one sub-category and nothing else lists it', () {
    final lifestyle = _mix()[1];

    expect(
      [for (final s in lifestyle.children) _row(s)],
      ['Lifestyle › Cooking: 6 videos, 2 channels'],
    );
  });

  test('channels subscribed to but never watched count as channels, not '
      'videos', () {
    final cooking = _mix()[1].children.single;

    expect(cooking.watchCount, 6);
    expect(cooking.channelCount, 2);
  });

  test('with nothing watched, every share is none', () {
    final mix = computeViewingMix(
      channels: const [(key: 'never', count: 0)],
      categoryOf: (key) => _categories[key],
    );

    expect(mix.single.share, 0);
  });

  group('a pick', () {
    test('of a category matches all of it', () {
      const pick = CategoryPick.category('Gaming');

      expect(pick.matches(_action), isTrue);
      expect(pick.matches(_gaming), isTrue);
      expect(pick.matches(_cooking), isFalse);
      expect(pick.matches(null), isFalse);
    });

    test('of a sub-category matches it alone', () {
      final pick = CategoryPick.of(_action);

      expect(pick.matches(_action), isTrue);
      expect(pick.matches(_puzzle), isFalse);
      expect(pick.matches(_gaming), isFalse);
    });

    test('of the channels only known by a category matches them alone', () {
      final pick = CategoryPick.of(_gaming);

      expect(pick.matches(_gaming), isTrue);
      expect(pick.matches(_action), isFalse);
    });

    test('of the uncategorized matches channels without a category', () {
      const pick = CategoryPick.uncategorized();

      expect(pick.matches(null), isTrue);
      expect(pick.matches(_gaming), isFalse);
    });
  });

  group('ticking', () {
    final gaming = _mix().first;
    final action = CategoryPick.of(_action);
    final puzzle = CategoryPick.of(_puzzle);
    final general = CategoryPick.of(_gaming);
    const whole = CategoryPick.category('Gaming');

    test('a category picks all of it, for its sub-categories too', () {
      final picks = togglePick({action}, whole, gaming);

      expect(picks, {whole});
      expect(pickState(picks, gaming), isTrue);
      expect(pickState(picks, gaming.children.first), isTrue);
    });

    test('some of its sub-categories leave it partly picked', () {
      final picks = togglePick(const {}, action, gaming);

      expect(picks, {action});
      expect(pickState(picks, gaming), isNull);
      expect(pickState(picks, gaming.children[1]), isFalse);
    });

    test('every sub-category picks the category', () {
      final picks = togglePick({action, puzzle}, general, gaming);

      expect(picks, {whole});
    });

    test('off a sub-category of a picked category keeps the rest', () {
      final picks = togglePick({whole}, puzzle, gaming);

      expect(picks, {action, general});
      expect(pickState(picks, gaming), isNull);
    });

    test('a partly picked category picks all of it', () {
      expect(togglePick({action}, whole, gaming), {whole});
    });

    test('a picked category again picks none of it', () {
      expect(togglePick({whole}, whole, gaming), isEmpty);
    });

    test('keeps what other categories have picked', () {
      const other = CategoryPick.uncategorized();

      expect(togglePick({other}, action, gaming), {other, action});
    });
  });
}
