import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/category_pipeline.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';

import '../../tool/tag_eval.dart';

void main() {
  group('an example not found', () {
    final channels = [
      for (final title in [
        'ArtemisBlue',
        'Usami Mizuki',
        'Keralis',
        'Artemis Gaming',
        'Hydreix Racing',
        'Cooking Daily',
      ])
        HistoryChannel(channelId: 'UC$title', title: title),
    ];

    test('is shown the channels named most like it, a one-word name too', () {
      expect(
        nearChannelNames(channels, 'Artimisblue'),
        contains('ArtemisBlue'),
      );
      expect(
        nearChannelNames(channels, 'Usami Mizuki 2.0'),
        contains('Usami Mizuki'),
      );
    });

    test('is shown no channel named nothing like it, and at most 3', () {
      expect(
        nearChannelNames(channels, 'Artimisblue'),
        isNot(contains('Cooking Daily')),
      );
      expect(nearChannelNames(channels, 'Zzzzqqq'), isEmpty);
      expect(
        nearChannelNames([
          for (var i = 0; i < 6; i++)
            HistoryChannel(channelId: 'UC$i', title: 'Keralis $i'),
        ], 'Keralis'),
        hasLength(3),
      );
    });
  });

  test("a pass's reach counts Claude's requests by what they ask, and the "
      'channels whose category only Claude named in the pass before', () {
    ChannelCategory from(CategorySource source) => ChannelCategory(
      path: const CategoryPath('Gaming'),
      source: source,
      decidedAt: DateTime.utc(2026, 10, 10),
    );

    final reach = claudeReach(
      {'a': ClaudeAsk.category, 'b': ClaudeAsk.tags, 'c': ClaudeAsk.tags},
      before: {
        'a': from(CategorySource.claude),
        'b': from(CategorySource.claude),
        'd': from(CategorySource.jev),
      },
    );

    expect(reach.categories, 1);
    expect(reach.tags, 2);
    expect(reach.categorizedByClaudeBefore, 2);
  });
}
