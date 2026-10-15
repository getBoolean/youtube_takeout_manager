import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/category_pipeline.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/name_key.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';
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

  group("a channel's report", () {
    final names = {
      nameKey('VTuber'): const TagName(
        name: 'VTuber',
        meaning: 'A streamer shown as an avatar',
      ),
      nameKey('Phase Connect'): const TagName(
        name: 'Phase Connect',
        meaning: 'A VTuber agency',
      ),
    };
    ChannelCategory result({
      CategoryPath? path = const CategoryPath('Entertainment', 'VTuber'),
      List<String> tags = const [],
    }) => ChannelCategory(
      path: path,
      tags: tags,
      decidedAt: DateTime.utc(2026, 10, 15),
    );

    test('shows the meaning of every tag the channel got, those Jev kept '
        'as well as those Claude added', () {
      final report = channelReport(
        result(tags: ['VTuber', 'Phase Connect']),
        withJev: true,
        said: (offered: 1, yes: {nameKey('VTuber'): 0.9}, other: 0.7),
        asked: ClaudeAsk.tags,
        names: names,
        known: {nameKey('VTuber')},
        wanted: ['Phase Connect', 'Music'],
      );

      expect(report.tags, hasLength(2));
      expect(report.tags.first, contains('A streamer shown as an avatar'));
      expect(report.tags.last, contains('A VTuber agency'));
      expect(report.hits, ['Phase Connect']);
    });

    test('tells a channel with no category from one with no tags to offer '
        'Jev', () {
      ChannelReport report(CategoryPath? path) => channelReport(
        result(path: path),
        withJev: true,
        said: null,
        asked: null,
        names: names,
        known: const {},
        wanted: const [],
      );

      expect(
        report(null).jev,
        isNot(report(const CategoryPath('Entertainment')).jev),
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
