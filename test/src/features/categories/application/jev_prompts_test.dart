import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/jev_prompts.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';

void main() {
  group("Jev's option keys", () {
    test('are one per name, even for names that read the same', () {
      final keys = jevOptionKeys(['C++', 'C#', 'Аниме', 'Аниме 2', 'None']);

      expect(keys.values, ['C++', 'C#', 'Аниме', 'Аниме 2', 'None']);
      expect(keys.keys.toSet(), hasLength(5));
      expect(keys.keys, isNot(contains(jevGeneral)));
    });

    test('say what they are, in plain ASCII', () {
      final keys = jevOptionKeys(['Hip hop', 'R&B']);

      for (final key in keys.keys) {
        expect(key, matches(RegExp(r'^[a-z0-9_]+$')));
      }
      expect(keys.keys.first, contains('hip'));
    });
  });

  test("the category question offers every category, leaving out one "
      'without sub-categories that was ruled out', () {
    final all = jevParentQuestion(youtubeTaxonomy);
    final without = jevParentQuestion(
      youtubeTaxonomy,
      exclude: const CategoryPath('Knowledge'),
    );

    expect(all.options, hasLength(youtubeTaxonomy.parents.length));
    expect(without.options, hasLength(youtubeTaxonomy.parents.length - 1));
  });

  test('the sub-category question offers "none of these" only when asked', () {
    final children = jevOptionKeys(['Racing', 'Puzzle']);

    expect(
      jevChildQuestion('Gaming', children, withGeneral: true).options.keys,
      contains(jevGeneral),
    );
    expect(
      jevChildQuestion('Gaming', children, withGeneral: false).options.keys,
      isNot(contains(jevGeneral)),
    );
  });

  test('the name check offers the sub-categories there are, and "a '
      'different one"', () {
    final question = jevSameQuestion('Gaming', jevOptionKeys(['Speedruns']));

    expect(question.options.values, contains('Speedruns'));
    expect(question.options.keys, contains(jevGeneral));
  });

  group("Jev's tag questions", () {
    const candidates = [
      (
        key: 'vtuberclips',
        tag: TagName(
          name: 'VTuber Clips',
          meaning: 'Clips of VTuber streams, made by someone else',
        ),
      ),
      (key: 'asmr', tag: TagName(name: 'ASMR')),
    ];
    final questions = jevTagQuestions(candidates);

    test('ask about each tag, taking its meaning as what yes means', () {
      final first = questions['tag_0']! as JevNoul;
      expect(first.instructions, contains('VTuber Clips'));
      expect(first.whenTrue, 'Clips of VTuber streams, made by someone else');
      expect((questions['tag_1']! as JevNoul).instructions, contains('ASMR'));
    });

    test('ask whether the channel is about something none of them name, '
        'naming them, since Jev reads each question alone', () {
      final other = questions['other']! as JevNoul;
      expect(other.instructions, contains('VTuber Clips'));
      expect(other.instructions, contains('ASMR'));
    });

    test("give how sure Jev is of each tag, by its key, and of 'other'", () {
      final read = readJevTags({
        'tag_0': const NoulAnswer(0.9),
        'tag_1': const NoulAnswer(0.2),
        'other': const NoulAnswer(0.7),
      }, candidates);

      expect(read.yes, {'vtuberclips': 0.9, 'asmr': 0.2});
      expect(read.other, 0.7);
    });
  });
}
