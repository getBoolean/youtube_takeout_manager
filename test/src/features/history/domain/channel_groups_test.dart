import 'package:flutter_test/flutter_test.dart';

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
      _watch('a3', channel: 'Alpha', channelId: 'UCa'),
      _watch('c1', channel: 'Gamma'),
    ],
  ),
);

ChannelGroups _group(
  Iterable<int> indices, {
  Set<int> nameMatches = const {},
}) => groupByChannel(
  channels: _loaded.watchedChannels,
  watchChannelIndex: _loaded.watchChannelIndex,
  watchIndices: indices,
  nameMatches: nameMatches,
);

/// Each group as its channel, then its videos' titles.
List<String> _shape(ChannelGroups groups) => [
  for (final g in groups.groups)
    '${g.channel?.title ?? g.key}: '
        '${[for (final i in g.indices) _loaded.history.watches[i].title].join(', ')}',
];

void main() {
  test('groups videos by channel, the most watched first, each channel '
      'newest first, and videos without a channel last', () {
    expect(_shape(_group([0, 1, 2, 3, 4, 5, 6])), [
      'Alpha: a1, a2, a3',
      'Beta: b1, b2',
      'Gamma: c1',
      '$noChannelGroupKey: gone',
    ]);
  });

  test('counts only the videos shown', () {
    expect(_shape(_group([2, 4, 5])), ['Beta: b1, b2', 'Alpha: a3']);
  });

  test('ties go by name', () {
    expect(_shape(_group([0, 2, 6])), ['Alpha: a1', 'Beta: b1', 'Gamma: c1']);
  });

  test('channels whose names match come before the rest', () {
    final gamma = _loaded.channelIndexByKey['name:Gamma']!;

    expect(
      _shape(_group([0, 2, 3, 6], nameMatches: {gamma})).first,
      'Gamma: c1',
    );
  });

  test('the whole history is grouped once, while loading', () {
    expect(
      _shape(_loaded.channelGroups),
      _shape(_group([0, 1, 2, 3, 4, 5, 6])),
    );
  });

  test('finds which group a video is in, and where', () {
    final groups = _group([0, 1, 2, 3, 4, 5, 6]);
    (int, int)? at(int watch) =>
        groups.locate(watch, _loaded.watchChannelIndex);

    expect(at(3), (0, 1));
    expect(at(4), (1, 1));
    expect(at(1), (3, 0));
  });

  test('a video not shown has no place', () {
    final groups = _group([0, 2]);

    expect(groups.locate(3, _loaded.watchChannelIndex), isNull);
    expect(groups.locate(6, _loaded.watchChannelIndex), isNull);
    expect(groups.locate(1, _loaded.watchChannelIndex), isNull);
  });

  test('channels subscribed to but never watched join as empty groups, '
      'before videos without a channel', () {
    final groups = _group([
      0,
      1,
    ]).withUnwatched(const [HistoryChannel(channelId: 'UCz', title: 'Zeta')]);

    expect(_shape(groups), ['Alpha: a1', 'Zeta: ', '$noChannelGroupKey: gone']);
    expect(groups.locate(1, _loaded.watchChannelIndex), (2, 0));
  });
}
