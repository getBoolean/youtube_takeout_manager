import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/category_groups.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/channel_groups.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';

WatchEntry _watch(String title, {String? channel, String? channelId}) =>
    WatchEntry(
      time: DateTime.utc(2026, 4, 12),
      kind: WatchKind.video,
      title: title,
      url: 'https://www.youtube.com/watch?v=${title.hashCode}',
      channelTitle: channel,
      channelUrl: channelId == null
          ? null
          : 'https://www.youtube.com/channel/$channelId',
    );

// Newest first.
final _loaded = LoadedHistory.of(
  TakeoutHistory(
    watches: [
      _watch('a1', channel: 'Alpha', channelId: 'UCa'),
      _watch('gone'),
      _watch('b1', channel: 'Beta', channelId: 'UCb'),
      _watch('a2', channel: 'Alpha', channelId: 'UCa'),
      _watch('b2', channel: 'Beta', channelId: 'UCb'),
      _watch('c1', channel: 'Gamma', channelId: 'UCc'),
      _watch('a3', channel: 'Alpha', channelId: 'UCa'),
      _watch('o1', channel: 'Omega', channelId: 'UCo'),
    ],
  ),
);

const _action = CategoryPath('Gaming', 'Action game');
const _cooking = CategoryPath('Lifestyle', 'Cooking');

final _categories = {
  'UCa': _action,
  'UCc': _action,
  'UCb': _cooking,
  'UCz': _cooking,
  'UCq': const CategoryPath('Knowledge'),
};

CategoryGroups _group(
  Iterable<int> indices, {
  List<HistoryChannel> unwatched = const [],
}) => groupByCategory(
  groupByChannel(
    channels: _loaded.watchedChannels,
    watchChannelIndex: _loaded.watchChannelIndex,
    watchIndices: indices,
  ).withUnwatched(unwatched),
  categoryOf: (key) => _categories[key],
);

/// Each group as its category, its videos' titles, and its channels.
List<String> _shape(CategoryGroups groups) => [
  for (final g in groups.groups)
    '${g.path?.label ?? g.key}: '
        '${[for (final i in g.indices) _loaded.history.watches[i].title].join(', ')}'
        ' (${g.channelCount})',
];

final _all = List.generate(_loaded.history.watches.length, (i) => i);

void main() {
  test('groups videos by the category of their channels, the most watched '
      'first, each newest first; then the uncategorized, then the videos '
      'without a channel', () {
    expect(_shape(_group(_all)), [
      'Gaming › Action game: a1, a2, c1, a3 (2)',
      'Lifestyle › Cooking: b1, b2 (1)',
      '$uncategorizedGroupKey: o1 (1)',
      '$noChannelGroupKey: gone (0)',
    ]);
  });

  test('has each video shown once', () {
    final groups = _group(_all);

    expect([for (final g in groups.groups) ...g.indices]..sort(), _all);
  });

  test("each category's share is of the videos with a channel", () {
    final shares = [for (final g in _group(_all).groups) g.share];

    expect(shares[0], closeTo(4 / 7, 1e-9));
    expect(shares[1], closeTo(2 / 7, 1e-9));
    expect(shares[2], closeTo(1 / 7, 1e-9));
  });

  test('channels subscribed to but never watched count in their category, '
      'and a category of only those comes after the watched ones', () {
    final groups = _group(
      _all,
      unwatched: const [
        HistoryChannel(channelId: 'UCz', title: 'Zeta'),
        HistoryChannel(channelId: 'UCq', title: 'Quiz'),
      ],
    );

    expect(_shape(groups), [
      'Gaming › Action game: a1, a2, c1, a3 (2)',
      'Lifestyle › Cooking: b1, b2 (2)',
      'Knowledge:  (1)',
      '$uncategorizedGroupKey: o1 (1)',
      '$noChannelGroupKey: gone (0)',
    ]);
  });

  test('only the videos shown are grouped', () {
    expect(_shape(_group([2, 4, 7])), [
      'Lifestyle › Cooking: b1, b2 (1)',
      '$uncategorizedGroupKey: o1 (1)',
    ]);
  });

  test("finds each video's group and place", () {
    final groups = _group(_all);

    expect(groups.locate(5, _loaded.watchChannelIndex), (0, 2));
    expect(groups.locate(1, _loaded.watchChannelIndex), (3, 0));
    expect(_group([2, 4]).locate(0, _loaded.watchChannelIndex), isNull);
  });
}
