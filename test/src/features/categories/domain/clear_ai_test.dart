import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/clear_ai.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';

final _then = DateTime.utc(2026, 9, 30);
final _now = DateTime.utc(2026, 10, 1);
const _ai = {
  CategorizationTier.youtube,
  CategorizationTier.jev,
  CategorizationTier.claude,
};

ChannelCategory _category(
  CategoryPath? path, {
  CategorySource source = CategorySource.youtube,
  double? jevAgreed,
  UserDecision decision = UserDecision.none,
  List<String> tags = const [],
  bool edited = false,
}) => ChannelCategory(
  path: path,
  source: source,
  jevAgreed: jevAgreed,
  confidence: source == CategorySource.jev ? 0.8 : null,
  reason: source == CategorySource.claude ? 'Because' : null,
  tried: _ai,
  prompts: const {'jevCheck': 'fp'},
  userDecision: decision,
  tags: tags,
  tagsTried: tags.isNotEmpty,
  tagsEditedByUser: edited,
  tagsPrompt: tags.isEmpty ? null : 'fp',
  decidedAt: _then,
);

/// YouTube's topics give UCj and UCc Gaming › Action; the rest nothing.
List<CategoryPath> _youtubeOf(String key) => switch (key) {
  'UCj' || 'UCc' => const [CategoryPath('Gaming', 'Action')],
  _ => const [],
};

AiResults _clear(
  Map<String, ChannelCategory> categories, {
  Map<String, List<SubCategory>> custom = const {},
  Map<String, TagName> tags = const {},
}) => clearAiResults(
  (categories: categories, custom: custom, tags: tags),
  youtubeOf: _youtubeOf,
  now: _now,
);

void main() {
  group('clearing AI results', () {
    test("puts a category Jev or Claude chose back to YouTube's, or to "
        'none, with no AI step counted as tried', () {
      final cleared = _clear({
        'UCj': _category(
          const CategoryPath('Gaming', 'Racing'),
          source: CategorySource.jev,
        ),
        'UCx': _category(
          const CategoryPath('Knowledge', 'Space'),
          source: CategorySource.claude,
        ),
      }).categories;

      final jev = cleared['UCj']!;
      expect(jev.path, const CategoryPath('Gaming', 'Action'));
      expect(jev.source, CategorySource.youtube);
      expect(jev.confidence, isNull);
      expect(jev.prompts, isEmpty);
      expect(jev.tried, {CategorizationTier.youtube});
      final claude = cleared['UCx']!;
      expect(claude.path, isNull);
      expect(claude.reason, isNull);
      expect(claude.tried, {CategorizationTier.youtube});
    });

    test("takes Jev's agreement off YouTube's categories, keeping them", () {
      final cleared = _clear({
        'UCy': _category(const CategoryPath('Music', 'Pop'), jevAgreed: 0.9),
      }).categories['UCy']!;

      expect(cleared.path, const CategoryPath('Music', 'Pop'));
      expect(cleared.jevAgreed, isNull);
      expect(cleared.prompts, isEmpty);
      expect(cleared.tried, {CategorizationTier.youtube});
    });

    test('removes the tags AI named, as not asked for', () {
      final cleared = _clear({
        'UCy': _category(const CategoryPath('Music'), tags: const ['ASMR']),
      }).categories['UCy']!;

      expect(cleared.tags, isEmpty);
      expect(cleared.tagsTried, isFalse);
      expect(cleared.tagsPrompt, isNull);
    });

    test(
      'keeps what the user decided, an AI suggestion they took among it',
      () {
        final decided = {
          'UCa': _category(
            const CategoryPath('Gaming', 'Speedruns'),
            source: CategorySource.claude,
            decision: UserDecision.accepted,
          ),
          'UCd': _category(
            const CategoryPath('Music'),
            source: CategorySource.jev,
            decision: UserDecision.denied,
          ),
          'UCu': _category(
            const CategoryPath('Knowledge', 'Space'),
            source: CategorySource.user,
          ),
        };

        final cleared = _clear(decided).categories;

        for (final MapEntry(:key, :value) in decided.entries) {
          expect(cleared[key]?.path, value.path, reason: key);
          expect(cleared[key]?.source, value.source, reason: key);
          expect(cleared[key]?.userDecision, value.userDecision, reason: key);
        }
      },
    );

    test('keeps tags the user edited', () {
      final cleared = _clear({
        'UCx': _category(
          const CategoryPath('Knowledge', 'Space'),
          source: CategorySource.claude,
          tags: const ['Mine'],
          edited: true,
        ),
      }).categories['UCx']!;

      expect(cleared.tags, ['Mine']);
      expect(cleared.tagsEditedByUser, isTrue);
    });

    test("keeps categories YouTube's topics gave", () {
      final youtube = _category(const CategoryPath('Gaming', 'Action'));

      expect(
        _clear({'UCc': youtube}).categories['UCc']?.path,
        const CategoryPath('Gaming', 'Action'),
      );
    });

    test('removes sub-categories AI made that no channel still has, keeping '
        "the ones they do, and the user's", () {
      final cleared = _clear(
        {
          'UCa': _category(
            const CategoryPath('Gaming', 'Speedruns'),
            source: CategorySource.claude,
            decision: UserDecision.accepted,
          ),
          'UCx': _category(
            const CategoryPath('Gaming', 'Retro'),
            source: CategorySource.claude,
          ),
        },
        custom: {
          'Gaming': [
            const SubCategory(name: 'Speedruns'),
            const SubCategory(name: 'Retro'),
            const SubCategory(name: 'Mine', origin: NameOrigin.user),
          ],
        },
      ).custom;

      expect(cleared, {
        'Gaming': [
          const SubCategory(name: 'Speedruns'),
          const SubCategory(name: 'Mine', origin: NameOrigin.user),
        ],
      });
    });

    test("removes tags AI made that no channel still has, keeping the "
        "user's", () {
      final cleared = _clear(
        {
          'UCx': _category(
            const CategoryPath('Knowledge'),
            tags: const ['Kept'],
            edited: true,
          ),
        },
        tags: {
          'kept': const TagName(name: 'Kept'),
          'gone': const TagName(name: 'Gone'),
          'typed': const TagName(name: 'Typed', origin: NameOrigin.user),
        },
      ).tags;

      expect(cleared.keys, unorderedEquals(['kept', 'typed']));
    });
  });

  test('the channels a clear sends back to AI are those not decided, or '
      'with tags not edited', () {
    expect(
      channelsToRedo({
        'UCa': _category(const CategoryPath('Music')),
        'UCb': _category(
          const CategoryPath('Music'),
          decision: UserDecision.accepted,
        ),
        'UCc': _category(
          const CategoryPath('Music'),
          decision: UserDecision.accepted,
          tags: const ['Mine'],
          edited: true,
        ),
      }),
      2,
    );
  });
}
