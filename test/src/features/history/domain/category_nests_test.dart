import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/category_nests.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/channel_groups.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';

/// A channel's group of [videos] watched videos, numbered from [first].
HistoryChannelGroup _group(String id, int videos, {int first = 0}) =>
    HistoryChannelGroup(
      key: id,
      channel: HistoryChannel(channelId: id, title: 'Channel $id'),
      indices: [for (var i = 0; i < videos; i++) first + i],
    );

const _action = CategoryPath('Gaming', 'Action game');
const _racing = CategoryPath('Gaming', 'Racing game');
const _pop = CategoryPath('Music', 'Pop music');

/// A list that says how long it is, and fails if anything in it is read.
class _Untouchable extends ListBase<int> {
  _Untouchable(this.length);

  @override
  int length;

  @override
  int operator [](int index) => throw StateError('A video list was read');

  @override
  void operator []=(int index, int value) => throw UnsupportedError('');
}

/// Each nest as its label, then its channels' keys.
List<Object> _shape(List<CategoryNest> nests) => [
  for (final nest in nests)
    [nest.pick.label, for (final group in nest.channels) group.key],
];

void main() {
  final paths = {'UCa': _action, 'UCr': _racing, 'UCp': _pop, 'UCn': null};

  test("channels nest under the picked rows their categories match, the "
      "most watched category first, each keeping the channels' order", () {
    final nests = nestByCategory(
      [_group('UCp', 5), _group('UCa', 3), _group('UCr', 2)],
      picks: {const CategoryPick.category('Gaming'), CategoryPick.of(_pop)},
      categoryOf: (key) => paths[key],
    );

    expect(_shape(nests), [
      ['Gaming', 'UCa', 'UCr'],
      ['Music › Pop music', 'UCp'],
    ]);
    expect(
      [for (final n in nests) (n.videoCount, n.channelCount, n.share)],
      [(5, 2, 0.5), (5, 1, 0.5)],
    );
  });

  test('the uncategorized come last, however much they were watched', () {
    final nests = nestByCategory(
      [_group('UCn', 9), _group('UCa', 1)],
      picks: {
        const CategoryPick.uncategorized(),
        const CategoryPick.category('Gaming'),
      },
      categoryOf: (key) => paths[key],
    );

    expect(_shape(nests), [
      ['Gaming', 'UCa'],
      ['Uncategorized', 'UCn'],
    ]);
  });

  test('a channel matching a picked category and its picked sub-category '
      'shows once, under the sub-category', () {
    final nests = nestByCategory(
      [_group('UCa', 3), _group('UCr', 2)],
      picks: {const CategoryPick.category('Gaming'), CategoryPick.of(_action)},
      categoryOf: (key) => paths[key],
    );

    expect(_shape(nests), [
      ['Gaming › Action game', 'UCa'],
      ['Gaming', 'UCr'],
    ]);
  });

  test('a channel shown only because it was picked itself nests under its '
      "own category's row", () {
    final nests = nestByCategory(
      [_group('UCa', 3), _group('UCp', 2), _group('UCn', 1)],
      picks: {CategoryPick.of(_action)},
      categoryOf: (key) => paths[key],
    );

    expect(_shape(nests), [
      ['Gaming › Action game', 'UCa'],
      ['Music', 'UCp'],
      ['Uncategorized', 'UCn'],
    ]);
  });

  test('the videos without a channel are left out', () {
    final nests = nestByCategory(
      [
        _group('UCa', 3),
        const HistoryChannelGroup(
          key: noChannelGroupKey,
          channel: null,
          indices: [7, 8],
        ),
      ],
      picks: {const CategoryPick.category('Gaming')},
      categoryOf: (key) => paths[key],
    );

    expect(_shape(nests), [
      ['Gaming', 'UCa'],
    ]);
  });

  test('2,000 channels nest without a video list read, each channel the '
      'same group as before', () {
    final groups = [
      for (var c = 0; c < 2000; c++)
        HistoryChannelGroup(
          key: 'UC$c',
          channel: HistoryChannel(channelId: 'UC$c', title: 'Channel $c'),
          indices: _Untouchable(30),
        ),
    ];

    final nests = nestByCategory(
      groups,
      picks: {const CategoryPick.category('Gaming')},
      categoryOf: (key) => key.hashCode.isEven ? _action : _pop,
    );
    final rows = [
      for (final nest in nests) NestedRows(nest.channels, (_) => false),
    ];

    expect(nests.expand((n) => n.channels).toSet(), groups.toSet());
    for (final nest in nests) {
      for (final group in nest.channels) {
        expect(
          identical(groups.firstWhere((g) => g.key == group.key), group),
          isTrue,
        );
      }
    }
    expect(
      [for (final r in rows) r.length],
      [for (final nest in nests) nest.channelCount],
    );
  });

  group("a nest's rows", () {
    final channels = [_group('UCa', 3), _group('UCr', 2, first: 3)];

    test('are its channels, each followed by its videos when open', () {
      final rows = NestedRows(channels, (key) => key == 'UCa');

      expect(
        [
          for (final row in rows)
            switch (row) {
              ChannelRow(:final group) => group.key,
              VideoRow(:final watchIndex) => watchIndex,
            },
        ],
        ['UCa', 0, 1, 2, 'UCr'],
      );
    });

    test('are only its channels while all are closed', () {
      expect(NestedRows(channels, (_) => false), hasLength(2));
    });
  });
}
