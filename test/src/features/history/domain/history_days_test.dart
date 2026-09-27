import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/domain/history_days.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';

// Local times, so days don't depend on the machine's time zone.
final _times = [
  DateTime(2026, 4, 12, 23, 59),
  DateTime(2026, 4, 12, 0, 1),
  DateTime(2026, 4, 11, 12),
  DateTime(2026, 4, 9, 8),
];

WatchEntry _watch(
  DateTime time, {
  String? channel,
  String? channelId,
  String id = 'v',
}) => WatchEntry(
  time: time.toUtc(),
  kind: WatchKind.video,
  title: 'Video $id',
  url: 'https://www.youtube.com/watch?v=$id',
  channelTitle: channel,
  channelUrl: channelId == null
      ? null
      : 'https://www.youtube.com/channel/$channelId',
);

void main() {
  group('days', () {
    final dayKeys = [for (final t in _times) dayKeyOf(t.toUtc())];

    test('entries are grouped by local day, newest first', () {
      final days = groupByDay([0, 1, 2, 3], dayKeys);

      expect(
        [for (final d in days) d.day],
        [DateTime(2026, 4, 12), DateTime(2026, 4, 11), DateTime(2026, 4, 9)],
      );
      expect(
        [for (final d in days) d.indices],
        [
          [0, 1],
          [2],
          [3],
        ],
      );
    });

    test('only the entries given are grouped', () {
      final days = groupByDay([1, 3], dayKeys);

      expect(
        [for (final d in days) d.indices],
        [
          [1],
          [3],
        ],
      );
    });

    test('jumping to a day finds that day', () {
      final days = groupByDay([0, 1, 2, 3], dayKeys);

      expect(
        dayGroupFor(days, DateTime(2026, 4, 11))?.day,
        DateTime(2026, 4, 11),
      );
    });

    test('jumping to a day without entries lands on the nearest older day', () {
      final days = groupByDay([0, 1, 2, 3], dayKeys);

      expect(
        dayGroupFor(days, DateTime(2026, 4, 10))?.day,
        DateTime(2026, 4, 9),
      );
    });

    test('jumping to before the first entry lands on the oldest day', () {
      final days = groupByDay([0, 1, 2, 3], dayKeys);

      expect(dayGroupFor(days, DateTime(2020))?.day, DateTime(2026, 4, 9));
      expect(dayGroupFor(const [], DateTime(2020)), isNull);
    });
  });

  group('watched channels', () {
    test('are ordered by how many videos were watched from each', () {
      final channels = countWatchedChannels([
        _watch(_times[0], channel: 'Rare', channelId: 'UCrare'),
        _watch(_times[1], channel: 'Often', channelId: 'UCoften'),
        _watch(_times[2], channel: 'Often', channelId: 'UCoften'),
        _watch(_times[3], channel: 'Often', channelId: 'UCoften'),
      ]);

      expect(
        [for (final c in channels) (c.channel.title, c.count)],
        [('Often', 3), ('Rare', 1)],
      );
      expect(channels.first.channel.channelId, 'UCoften');
      expect(channels.first.lastWatched, _times[1].toUtc());
    });

    test('a renamed channel counts as one, by its newest name', () {
      final channels = countWatchedChannels([
        _watch(_times[0], channel: 'New name', channelId: 'UCsame'),
        _watch(_times[1], channel: 'Old name', channelId: 'UCsame'),
      ]);

      expect(
        [for (final c in channels) (c.channel.title, c.count)],
        [('New name', 2)],
      );
    });

    test('videos with no channel are left out', () {
      final channels = countWatchedChannels([_watch(_times[0])]);

      expect(channels, isEmpty);
    });

    test('a channel matches a watch by its ID, else its name', () {
      final byId = countWatchedChannels([
        _watch(_times[0], channel: 'Named', channelId: 'UCid'),
      ]).single;
      final byName = countWatchedChannels([
        _watch(_times[0], channel: 'No ID'),
      ]).single;

      expect(
        byId.channel.matches(
          _watch(_times[1], channel: 'Other', channelId: 'UCid'),
        ),
        isTrue,
      );
      expect(
        byId.channel.matches(_watch(_times[1], channel: 'Named')),
        isFalse,
      );
      expect(
        byName.channel.matches(_watch(_times[1], channel: 'No ID')),
        isTrue,
      );
    });
  });
}
