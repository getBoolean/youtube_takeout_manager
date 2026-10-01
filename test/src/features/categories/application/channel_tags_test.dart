import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c
    ..listen(tagNamesProvider, (_, _) {})
    ..listen(tagUsageProvider, (_, _) {});
  return c;
}

void main() {
  group('tags named for a channel', () {
    test('reuse the spelling there is, whatever its case or hyphens, and '
        'keep new ones', () async {
      final c = _container();
      final tags = c.read(tagNamesProvider.notifier);
      await tags.resolve(['Mario Kart World'], NameOrigin.ai);

      final resolved = await tags.resolve([
        'mario-kart world',
        'Blue Archive',
      ], NameOrigin.ai);

      expect(resolved, ['Mario Kart World', 'Blue Archive']);
      final later = _container();
      expect(
        (await later.read(tagNamesProvider.future)).values.map((t) => t.name),
        containsAll(['Mario Kart World', 'Blue Archive']),
      );
    });

    test('are tidied, blanks and repeats left out, at most five', () async {
      final c = _container();

      final resolved = await c.read(tagNamesProvider.notifier).resolve([
        '  ASMR  ',
        '',
        'asmr',
        'One',
        'Two',
        'Three',
        'Four',
        'Five',
        'x' * 60,
      ], NameOrigin.ai);

      expect(resolved, ['ASMR', 'One', 'Two', 'Three', 'Four']);
    });

    test(
      'one the user types that folds into one AI made stays AI-made',
      () async {
        final c = _container();
        final tags = c.read(tagNamesProvider.notifier);
        await tags.resolve(['Speedruns'], NameOrigin.ai);

        expect(await tags.resolve(['speed-runs'], NameOrigin.user), [
          'Speedruns',
        ]);

        final kept = await c.read(tagNamesProvider.future);
        expect(kept.values.single.origin, NameOrigin.ai);
      },
    );

    test('a new one the user types is theirs', () async {
      final c = _container();

      await c.read(tagNamesProvider.notifier).resolve([
        'Jazz piano',
      ], NameOrigin.user);

      final kept = await c.read(tagNamesProvider.future);
      expect(
        kept.values.single,
        const TagName(name: 'Jazz piano', origin: NameOrigin.user),
      );
    });
  });

  test('tags in use are counted by channel, the most used first', () async {
    final c = _container();
    await c.read(tagNamesProvider.notifier).resolve([
      'ASMR',
      'Speedruns',
    ], NameOrigin.ai);
    ChannelCategory tagged(List<String> tags) => ChannelCategory(
      path: const CategoryPath('Gaming'),
      tags: tags,
      tagsTried: true,
      decidedAt: DateTime.utc(2026, 10, 1),
    );
    await c.read(channelCategoriesProvider.future);

    await c.read(channelCategoriesProvider.notifier).replaceAll({
      'UCa': tagged(['ASMR']),
      'UCb': tagged(['Speedruns', 'ASMR']),
      'UCc': tagged(['ASMR']),
      'UCd': tagged(['Speedruns']),
      'UCe': tagged(['Cooking']),
    });

    expect(c.read(tagUsageProvider), [
      (name: 'ASMR', channels: 3, origin: NameOrigin.ai),
      (name: 'Speedruns', channels: 2, origin: NameOrigin.ai),
      (name: 'Cooking', channels: 1, origin: NameOrigin.ai),
    ]);
  });
}
