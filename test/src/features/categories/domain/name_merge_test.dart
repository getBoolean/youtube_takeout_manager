import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/name_merge.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';

ChannelCategory _category(
  String parent,
  String? child, {
  DateTime? at,
  List<ScoredPath> runnersUp = const [],
  UserDecision decision = UserDecision.none,
}) => ChannelCategory(
  path: CategoryPath(parent, child),
  source: CategorySource.claude,
  runnersUp: runnersUp,
  userDecision: decision,
  decidedAt: at ?? DateTime.utc(2026, 9, 30),
);

/// [names] as records AI made.
Map<String, List<SubCategory>> _records(Map<String, List<String>> names) => {
  for (final MapEntry(:key, :value) in names.entries)
    key: [for (final name in value) SubCategory(name: name)],
};

StoredNames _merge(
  Map<String, ChannelCategory> categories, [
  Map<String, List<String>> custom = const {},
]) => mergeNameVariants((categories: categories, custom: _records(custom)));

void main() {
  test("variants of YouTube's sub-category take YouTube's spelling, and "
      "leave the AI-made list", () {
    final merged = _merge(
      {'UCa': _category('Music', 'Hip-hop')},
      {
        'Music': ['Hip-hop', 'Shoegaze'],
        'Gaming': ['Role playing'],
      },
    );

    expect(
      merged.categories['UCa']?.path,
      const CategoryPath('Music', 'Hip hop'),
    );
    expect(subCategoryNames(merged.custom), {
      'Music': ['Shoegaze'],
    });
  });

  test('otherwise the spelling the most channels use wins, and every '
      'channel moves to it', () {
    final merged = _merge(
      {
        'UCa': _category('Gaming', 'Speedruns'),
        'UCb': _category('Gaming', 'Speedruns'),
        'UCc': _category('Gaming', 'Speed-runs'),
      },
      {
        'Gaming': ['Speed-runs', 'Speedruns'],
      },
    );

    expect(
      {for (final e in merged.categories.entries) e.key: e.value.path?.child},
      {'UCa': 'Speedruns', 'UCb': 'Speedruns', 'UCc': 'Speedruns'},
    );
    expect(subCategoryNames(merged.custom), {
      'Gaming': ['Speedruns'],
    });
  });

  test('a tie goes to the one AI made first', () {
    final merged = _merge(
      {
        'UCa': _category('Gaming', 'Speedruns'),
        'UCb': _category('Gaming', 'Speed-runs'),
      },
      {
        'Gaming': ['Speed-runs', 'Speedruns'],
      },
    );

    expect(merged.categories['UCa']?.path?.child, 'Speed-runs');
    expect(subCategoryNames(merged.custom), {
      'Gaming': ['Speed-runs'],
    });
  });

  test('a tie between spellings only channels have goes to the earliest', () {
    final merged = _merge({
      'UCa': _category('Gaming', 'speed runs', at: DateTime.utc(2026, 9, 2)),
      'UCb': _category('Gaming', 'Speed runs', at: DateTime.utc(2026, 9, 1)),
    });

    expect(merged.categories['UCa']?.path?.child, 'Speed runs');
    expect(merged.categories['UCb']?.path?.child, 'Speed runs');
  });

  test('runners-up move too, without the same one twice', () {
    final merged = _merge(
      {
        'UCa': _category(
          'Music',
          'Pop',
          runnersUp: const [
            ScoredPath(path: CategoryPath('Gaming', 'Speed-runs'), score: 0.3),
            ScoredPath(path: CategoryPath('Gaming', 'Speedruns'), score: 0.2),
            ScoredPath(path: CategoryPath('Music', 'Rock'), score: 0.1),
          ],
        ),
        'UCb': _category('Gaming', 'Speedruns'),
      },
      {
        'Gaming': ['Speed-runs', 'Speedruns'],
      },
    );

    expect(merged.categories['UCa']?.runnersUp, const [
      ScoredPath(path: CategoryPath('Gaming', 'Speedruns'), score: 0.3),
      ScoredPath(path: CategoryPath('Music', 'Rock'), score: 0.1),
    ]);
  });

  test('names that differ by a sharp stay apart', () {
    final merged = _merge(
      {
        'UCa': _category('Knowledge', 'C programming'),
        'UCb': _category('Knowledge', 'C# programming'),
      },
      {
        'Knowledge': ['C programming', 'C# programming'],
      },
    );

    expect(merged.categories['UCb']?.path?.child, 'C# programming');
    expect(subCategoryNames(merged.custom), {
      'Knowledge': ['C programming', 'C# programming'],
    });
  });

  test('the same name under different categories stays apart', () {
    final merged = _merge(
      {'UCa': _category('Gaming', 'Retro'), 'UCb': _category('Music', 'retro')},
      {
        'Gaming': ['Retro'],
        'Music': ['retro'],
      },
    );

    expect(
      merged.categories['UCb']?.path,
      const CategoryPath('Music', 'retro'),
    );
    expect(subCategoryNames(merged.custom), {
      'Gaming': ['Retro'],
      'Music': ['retro'],
    });
  });

  test('a category the user accepted moves, and stays accepted', () {
    final merged = _merge(
      {
        'UCa': _category('Gaming', 'Speedruns'),
        'UCb': _category('Gaming', 'Speedruns'),
        'UCc': _category(
          'Gaming',
          'speed-runs',
          decision: UserDecision.accepted,
        ),
      },
      {
        'Gaming': ['Speedruns', 'speed-runs'],
      },
    );

    final accepted = merged.categories['UCc'];
    expect(accepted?.path, const CategoryPath('Gaming', 'Speedruns'));
    expect(accepted?.userDecision, UserDecision.accepted);
  });

  test('with nothing to merge, everything is left just as it was', () {
    final categories = {
      'UCa': _category('Gaming', 'Speedruns'),
      'UCb': _category('Music', 'Pop'),
      'UCc': ChannelCategory(decidedAt: DateTime.utc(2026, 9, 30)),
    };
    final custom = _records({
      'Gaming': ['Speedruns'],
    });

    final merged = mergeNameVariants((categories: categories, custom: custom));

    for (final MapEntry(:key, :value) in categories.entries) {
      expect(identical(merged.categories[key], value), isTrue, reason: key);
    }
    expect(identical(merged.custom['Gaming'], custom['Gaming']), isTrue);
  });

  test('merging what was merged changes nothing', () {
    final once = _merge(
      {
        'UCa': _category('Gaming', 'Speedruns'),
        'UCb': _category('Gaming', 'Speed-runs'),
        'UCc': _category('Music', 'Hip-hop'),
      },
      {
        'Gaming': ['Speed-runs', 'Speedruns'],
        'Music': ['Hip-hop'],
      },
    );

    final twice = mergeNameVariants(once);

    for (final MapEntry(:key, :value) in once.categories.entries) {
      expect(identical(twice.categories[key], value), isTrue, reason: key);
    }
    expect(twice.custom, once.custom);
  });

  test('the spelling that wins keeps an emoji a variant had', () {
    final merged = mergeNameVariants((
      categories: {
        'UCa': _category('Gaming', 'Speedruns'),
        'UCb': _category('Gaming', 'Speedruns'),
      },
      custom: {
        'Gaming': [
          const SubCategory(name: 'Speed-runs', emoji: '🏃'),
          const SubCategory(name: 'Speedruns'),
        ],
      },
    ));

    expect(merged.custom, {
      'Gaming': [const SubCategory(name: 'Speedruns', emoji: '🏃')],
    });
  });

  test('a name the user typed stays theirs when it wins', () {
    final merged = mergeNameVariants((
      categories: {'UCa': _category('Gaming', 'Speedruns')},
      custom: {
        'Gaming': [
          const SubCategory(name: 'Speedruns', origin: NameOrigin.user),
          const SubCategory(name: 'speed runs'),
        ],
      },
    ));

    expect(merged.custom['Gaming'], [
      const SubCategory(name: 'Speedruns', origin: NameOrigin.user),
    ]);
  });
}
