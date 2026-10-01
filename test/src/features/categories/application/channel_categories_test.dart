import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.listen(channelCategoriesProvider, (_, _) {});
  return c;
}

void main() {
  final decidedAt = DateTime.utc(2026, 10, 1);

  test("an AI run's answer for a channel the user decided brings only its "
      'tags', () async {
    final c = _container();
    final categories = c.read(channelCategoriesProvider.notifier);
    await categories.decide(
      'UCa',
      ChannelCategory(
        path: const CategoryPath('Music'),
        source: CategorySource.user,
        decidedAt: decidedAt,
      ),
    );

    await categories.putAiResult(
      'UCa',
      ChannelCategory(
        path: const CategoryPath('Gaming'),
        source: CategorySource.claude,
        tags: const ['Mario Kart World'],
        tagsTried: true,
        decidedAt: decidedAt,
      ),
    );

    final kept = (await c.read(channelCategoriesProvider.future))['UCa']!;
    expect(kept.path, const CategoryPath('Music'));
    expect(kept.tags, ['Mario Kart World']);
  });

  group('a sub-category added', () {
    test('keeps who made it and its emoji', () async {
      final c = _container();
      final custom = c.read(customCategoriesProvider.notifier);

      await custom.add('Gaming', 'Retro', origin: NameOrigin.user, emoji: '👾');

      expect((await c.read(customCategoriesProvider.future))['Gaming'], [
        const SubCategory(name: 'Retro', origin: NameOrigin.user, emoji: '👾'),
      ]);
    });

    test('that folds into one AI made is the one AI made', () async {
      final c = _container();
      final custom = c.read(customCategoriesProvider.notifier);
      await custom.add('Gaming', 'Speedruns', emoji: '🏃');

      final spelled = await custom.add(
        'Gaming',
        'speed-runs',
        origin: NameOrigin.user,
        emoji: '⏱️',
      );

      expect(spelled, 'Speedruns');
      expect((await c.read(customCategoriesProvider.future))['Gaming'], [
        const SubCategory(name: 'Speedruns', emoji: '🏃'),
      ]);
    });
  });

  test('replacing every category keeps them on this device', () async {
    final first = _container();
    await first.read(channelCategoriesProvider.future);

    await first.read(channelCategoriesProvider.notifier).replaceAll({
      'UCb': ChannelCategory(
        path: const CategoryPath('Sports'),
        decidedAt: decidedAt,
      ),
    });

    final later = _container();
    expect((await later.read(channelCategoriesProvider.future)).keys, ['UCb']);
  });
}
