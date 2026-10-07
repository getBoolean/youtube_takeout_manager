import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/category_editor.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/tag_editor.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';

final _now = DateTime.utc(2026, 10, 6, 12);

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [
      tagEditorProvider.overrideWith(() => TagEditor(now: () => _now)),
    ],
  );
  addTearDown(c.dispose);
  c
    ..listen(tagNamesProvider, (_, _) {})
    ..listen(channelCategoriesProvider, (_, _) {});
  return c;
}

Future<Map<String, TagName>> _tags(ProviderContainer c) =>
    c.read(tagNamesProvider.future);

void main() {
  test("a tag defined with a meaning is the user's, and marked changed so "
      'channels are checked for it', () async {
    final c = _container();

    final spelled = await c
        .read(tagEditorProvider.notifier)
        .define(
          '  Loli/Lolicon ',
          meaning: 'Anime art of childlike characters',
        );

    expect(spelled, 'Loli/Lolicon');
    final tag = (await _tags(c))['lolilolicon'];
    expect(tag?.origin, NameOrigin.user);
    expect(tag?.meaning, 'Anime art of childlike characters');
    expect(tag?.changedAt, _now);
    expect(tag?.offeredToAi, isTrue);
  });

  test('a tag defined without a meaning is offered to no AI', () async {
    final c = _container();

    await c.read(tagEditorProvider.notifier).define('Watch later');

    final tag = (await _tags(c))['watchlater'];
    expect(tag?.offeredToAi, isFalse);
    expect(tag?.changedAt, isNull);
  });

  test("defining a tag AI named makes it the user's, keeping its spelling, "
      'and brings back one deleted', () async {
    final c = _container();
    final tags = c.read(tagNamesProvider.notifier);
    await tags.put('vtuber', const TagName(name: 'VTuber'));
    await tags.put('gone', const TagName(name: 'Gone', deleted: true));
    final editor = c.read(tagEditorProvider.notifier);

    expect(
      await editor.define('vtuber', meaning: 'A virtual YouTuber'),
      'VTuber',
    );
    await editor.define('Gone');

    final kept = await _tags(c);
    expect(kept['vtuber']?.origin, NameOrigin.user);
    expect(kept['vtuber']?.meaning, 'A virtual YouTuber');
    expect(kept['gone']?.deleted, isFalse);
  });

  test("changing an AI-named tag's meaning makes it the user's", () async {
    final c = _container();
    await c
        .read(tagNamesProvider.notifier)
        .put('asmr', const TagName(name: 'ASMR', meaning: 'Whispers'));

    await c
        .read(tagEditorProvider.notifier)
        .setMeaning('asmr', 'Relaxing sounds and whispers');

    final tag = (await _tags(c))['asmr'];
    expect(tag?.origin, NameOrigin.user);
    expect(tag?.meaning, 'Relaxing sounds and whispers');
    expect(tag?.changedAt, _now);
  });

  test('deleting a tag takes it off every channel, edited ones too, and an '
      'answer naming it later brings it back nowhere', () async {
    final c = _container();
    await c.read(tagNamesProvider.notifier).resolve([
      'ASMR',
      'Roleplay',
    ], NameOrigin.ai);
    await c.read(channelCategoriesProvider.future);
    await c.read(channelCategoriesProvider.notifier).replaceAll({
      'UCa': ChannelCategory(
        tags: const ['ASMR', 'Roleplay'],
        tagsTried: true,
        decidedAt: _now,
      ),
    });
    await c.read(categoryEditorProvider.notifier).setTags(
      const HistoryChannel(channelId: 'UCe', title: 'Edited'),
      ['ASMR'],
    );

    await c.read(tagEditorProvider.notifier).delete('asmr');

    final categories = await c.read(channelCategoriesProvider.future);
    expect(categories['UCa']?.tags, ['Roleplay']);
    expect(categories['UCe']?.tags, isEmpty);
    expect(categories['UCe']?.tagsAddedByUser, isEmpty);
    expect(
      await c.read(tagNamesProvider.notifier).resolve(['asmr'], NameOrigin.ai),
      isEmpty,
    );
  });
}
