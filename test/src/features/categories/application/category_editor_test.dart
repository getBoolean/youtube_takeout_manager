import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/category_editor.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';

const _gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c
    ..listen(channelCategoriesProvider, (_, _) {})
    ..listen(customCategoriesProvider, (_, _) {})
    ..listen(categoryTaxonomyProvider, (_, _) {})
    ..listen(tagNamesProvider, (_, _) {});
  return c;
}

Future<ChannelCategory?> _kept(ProviderContainer c) async =>
    (await c.read(channelCategoriesProvider.future))['UCg'];

final _now = DateTime.utc(2026, 10, 1);

/// Gamer's category to start from: YouTube's, with tags AI named, or
/// [edited] ones.
Future<void> _start(ProviderContainer c, {bool edited = false}) async {
  await c.read(channelCategoriesProvider.future);
  await c
      .read(channelCategoriesProvider.notifier)
      .decide(
        'UCg',
        ChannelCategory(
          path: const CategoryPath('Gaming', 'Action'),
          tags: const ['Old tag'],
          tagsTried: true,
          tagsEditedByUser: edited,
          decidedAt: _now,
        ),
      );
}

void main() {
  group('accepting what AI suggests', () {
    test('makes it the category, as the user chose, with its tags', () async {
      final c = _container();
      await _start(c);

      await c
          .read(categoryEditorProvider.notifier)
          .accept(
            _gamer,
            ChannelCategory(
              path: const CategoryPath('Gaming', 'Speed runs'),
              source: CategorySource.claude,
              tags: const ['Super Metroid'],
              tagsTried: true,
              decidedAt: _now,
            ),
          );

      final kept = await _kept(c);
      expect(kept?.path, const CategoryPath('Gaming', 'Speed runs'));
      expect(kept?.userDecision, UserDecision.accepted);
      expect(kept?.tags, ['Super Metroid']);
      expect(kept?.tagsEditedByUser, isTrue);
      final custom = await c.read(customCategoriesProvider.future);
      expect(custom['Gaming'], [const SubCategory(name: 'Speed runs')]);
    });

    test('keeps tags the user edited, changing only the category', () async {
      final c = _container();
      await _start(c, edited: true);

      await c
          .read(categoryEditorProvider.notifier)
          .accept(
            _gamer,
            ChannelCategory(
              path: const CategoryPath('Gaming', 'Racing'),
              source: CategorySource.claude,
              tags: const ['Super Metroid'],
              tagsTried: true,
              decidedAt: _now,
            ),
          );

      final kept = await _kept(c);
      expect(kept?.path, const CategoryPath('Gaming', 'Racing'));
      expect(kept?.tags, ['Old tag']);
    });
  });

  test('keeping the category there is protects it', () async {
    final c = _container();
    await _start(c);

    await c.read(categoryEditorProvider.notifier).deny(_gamer);

    final kept = await _kept(c);
    expect(kept?.path, const CategoryPath('Gaming', 'Action'));
    expect(kept?.userDecision, UserDecision.denied);
  });

  test("using YouTube's category makes it the user's choice, keeping the "
      'tags', () async {
    final c = _container();
    await _start(c);

    await c
        .read(categoryEditorProvider.notifier)
        .useYouTube(_gamer, const CategoryPath('Gaming', 'Racing'));

    final kept = await _kept(c);
    expect(kept?.path, const CategoryPath('Gaming', 'Racing'));
    expect(kept?.source, CategorySource.youtube);
    expect(kept?.userDecision, UserDecision.accepted);
    expect(kept?.tags, ['Old tag']);
  });

  test('choosing a category makes it the user\'s, keeping the tags', () async {
    final c = _container();
    await _start(c);

    await c
        .read(categoryEditorProvider.notifier)
        .choose(_gamer, const CategoryPath('Music', 'jazz'));

    final kept = await _kept(c);
    expect(kept?.path, const CategoryPath('Music', 'Jazz'));
    expect(kept?.source, CategorySource.user);
    expect(kept?.userDecision, UserDecision.accepted);
    expect(kept?.tags, ['Old tag']);
  });

  test('choosing a category for a channel with none gives it one', () async {
    final c = _container();
    await c.read(channelCategoriesProvider.future);

    await c
        .read(categoryEditorProvider.notifier)
        .choose(_gamer, const CategoryPath('Knowledge'));

    expect((await _kept(c))?.path, const CategoryPath('Knowledge'));
  });

  group('a new sub-category typed in', () {
    test("is the user's, with the emoji they picked", () async {
      final c = _container();

      final path = await c
          .read(categoryEditorProvider.notifier)
          .addSubCategory('Gaming', '  Retro  games ', emoji: '👾');

      expect(path, const CategoryPath('Gaming', 'Retro games'));
      expect((await c.read(customCategoriesProvider.future))['Gaming'], [
        const SubCategory(
          name: 'Retro games',
          origin: NameOrigin.user,
          emoji: '👾',
        ),
      ]);
    });

    test('that folds into one AI made is that one', () async {
      final c = _container();
      await c
          .read(customCategoriesProvider.notifier)
          .add('Gaming', 'Speedruns');

      final path = await c
          .read(categoryEditorProvider.notifier)
          .addSubCategory('Gaming', 'speed-runs');

      expect(path, const CategoryPath('Gaming', 'Speedruns'));
      expect(
        (await c.read(
          customCategoriesProvider.future,
        ))['Gaming']!.single.origin,
        NameOrigin.ai,
      );
    });

    test("that folds into one of YouTube's is YouTube's", () async {
      final c = _container();

      final path = await c
          .read(categoryEditorProvider.notifier)
          .addSubCategory('Music', 'hip-hop');

      expect(path, const CategoryPath('Music', 'Hip hop'));
    });
  });

  test(
    "setting a channel's tags marks them as the user's, at most five",
    () async {
      final c = _container();
      await _start(c);

      await c.read(categoryEditorProvider.notifier).setTags(_gamer, [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
      ]);

      final kept = await _kept(c);
      expect(kept?.tags, ['A', 'B', 'C', 'D', 'E']);
      expect(kept?.tagsEditedByUser, isTrue);
      final names = await c.read(tagNamesProvider.future);
      expect(names.values.every((t) => t.origin == NameOrigin.user), isTrue);
    },
  );
}
