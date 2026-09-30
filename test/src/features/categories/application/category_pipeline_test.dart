import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/category_pipeline.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';

String _topic(String slug) => 'https://en.wikipedia.org/wiki/$slug';

/// Jev, answering from a script: how likely yes is for each category it's
/// asked about, and the option it picks with how likely each is.
class _Jev extends TypeSafeRepository {
  _Jev({this.fits = const {}, this.parent, this.child});

  /// How likely yes is, by the category's label.
  final Map<String, double> fits;
  final Map<String, double>? parent;
  final Map<String, double>? child;

  /// The questions asked, per request.
  final requests = <Map<String, JevQuestion>>[];

  @override
  Future<Map<String, JevAnswer>> ask({
    required String apiKey,
    required Object state,
    required Map<String, JevQuestion> questions,
  }) async {
    requests.add(questions);
    return {
      for (final MapEntry(:key, :value) in questions.entries)
        key: switch (value) {
          JevNoul(:final instructions) => NoulAnswer(
            fits.entries
                    .where((f) => instructions.contains('"${f.key}"'))
                    .firstOrNull
                    ?.value ??
                0,
          ),
          JevChoice(:final options) => _choose(
            options,
            key == 'parent' ? parent : child,
          ),
        },
    };
  }

  /// Picks the likeliest of [options] by the names in [odds].
  static ChoiceAnswer _choose(
    Map<String, String?> options,
    Map<String, double>? odds,
  ) {
    String keyOf(String name) => options.entries
        .firstWhere(
          (o) => o.key == name || (o.value?.startsWith(name) ?? false),
          orElse: () => options.entries.first,
        )
        .key;
    final probabilities = {
      for (final MapEntry(:key, :value) in (odds ?? const {}).entries)
        keyOf(key): value,
    };
    // Not scripted: no confidence in anything.
    if (probabilities.isEmpty) {
      return ChoiceAnswer(
        choice: options.keys.first,
        probabilities: {options.keys.first: 0},
        confidence: 0,
      );
    }
    final best = probabilities.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return ChoiceAnswer(
      choice: best.key,
      probabilities: probabilities,
      confidence: best.value,
    );
  }
}

ChannelInput _input({List<String> topics = const []}) => (
  key: 'UCg',
  topicUrls: topics,
  evidence: const ChannelEvidence(
    title: 'Speedy',
    recentTitles: ['Any% in 10 minutes'],
  ),
);

CategoryPipeline _pipeline(_Jev jev) => CategoryPipeline(
  taxonomy: youtubeTaxonomy.withCustom({
    'Gaming': ['Speedruns'],
  }),
  jev: (repository: jev, apiKey: 'jv_live_1'),
);

void main() {
  test("without Jev, YouTube's category is taken as it is", () async {
    final category = await CategoryPipeline(
      taxonomy: youtubeTaxonomy,
    ).categorize(_input(topics: [_topic('Action_game')]));

    expect(category.path, const CategoryPath('Gaming', 'Action'));
    expect(category.source, CategorySource.youtube);
    expect(category.tried, {CategorizationTier.youtube});
  });

  test("when Jev agrees with YouTube's category, it's kept, with how sure "
      'Jev is', () async {
    final jev = _Jev(fits: {'Gaming › Action': 0.9});

    final category = await _pipeline(
      jev,
    ).categorize(_input(topics: [_topic('Action_game')]));

    expect(category.path, const CategoryPath('Gaming', 'Action'));
    expect(category.source, CategorySource.youtube);
    expect(category.jevAgreed, 0.9);
    expect(category.tried, {
      CategorizationTier.youtube,
      CategorizationTier.jev,
    });
    // One request did it.
    expect(jev.requests, hasLength(1));
  });

  test('of several YouTube categories, the one Jev agrees with most is '
      'kept', () async {
    final jev = _Jev(
      fits: {'Gaming › Action': 0.7, 'Gaming › Role-playing': 0.95},
    );

    final category = await _pipeline(jev).categorize(
      _input(
        topics: [_topic('Action_game'), _topic('Role-playing_video_game')],
      ),
    );

    expect(category.path, const CategoryPath('Gaming', 'Role-playing'));
  });

  test('when Jev disagrees, it picks from every category, including ones '
      'AI made before', () async {
    final jev = _Jev(
      fits: {'Gaming › Action': 0.2},
      parent: {'Gaming': 0.9, 'Music': 0.1},
      child: {'Speedruns': 0.8, 'Action': 0.15},
    );

    final category = await _pipeline(
      jev,
    ).categorize(_input(topics: [_topic('Action_game')]));

    expect(category.path, const CategoryPath('Gaming', 'Speedruns'));
    expect(category.source, CategorySource.jev);
    expect(category.isAi, isTrue);
    expect(category.confidence, closeTo(sqrt(0.9 * 0.8), 0.001));
    expect([
      for (final r in category.runnersUp) r.path,
    ], contains(const CategoryPath('Gaming', 'Action')));
    expect(category.jevAgreed, 0.2);
  });

  test('without YouTube topics, Jev picks from the names and titles', () async {
    final jev = _Jev(
      parent: {'Gaming': 0.95, 'Music': 0.05},
      child: {'Speedruns': 0.9, 'Action': 0.1},
    );

    final category = await _pipeline(jev).categorize(_input());

    expect(category.path, const CategoryPath('Gaming', 'Speedruns'));
    expect(category.hadTopics, isFalse);
    // No YouTube category to check.
    expect(jev.requests.first.values.whereType<JevNoul>(), isEmpty);
  });

  test('a category with no sub-categories is picked in one step', () async {
    final jev = _Jev(parent: {'Knowledge': 0.8, 'Gaming': 0.2});

    final category = await _pipeline(jev).categorize(_input());

    expect(category.path, const CategoryPath('Knowledge'));
    expect(category.confidence, closeTo(0.8, 0.001));
    expect(jev.requests, hasLength(1));
  });

  test(
    "when none fits better than the category itself, that's the pick",
    () async {
      final jev = _Jev(
        parent: {'Gaming': 0.9, 'Music': 0.1},
        child: {'None': 0.85, 'Action': 0.15},
      );

      final category = await _pipeline(jev).categorize(_input());

      expect(category.path, const CategoryPath('Gaming'));
    },
  );

  test("when Jev isn't sure of its own pick either, YouTube's category "
      'stays', () async {
    final jev = _Jev(
      fits: {'Gaming › Action': 0.3},
      parent: {'Gaming': 0.5, 'Music': 0.5},
      child: {'Speedruns': 0.4, 'Action': 0.6},
    );

    final category = await _pipeline(
      jev,
    ).categorize(_input(topics: [_topic('Action_game')]));

    expect(category.path, const CategoryPath('Gaming', 'Action'));
    expect(category.source, CategorySource.youtube);
    expect(category.jevAgreed, 0.3);
  });
}
