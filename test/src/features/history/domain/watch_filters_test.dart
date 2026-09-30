import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';

WatchedChannel _watched(String title, {String? id, int count = 1}) =>
    WatchedChannel(
      channel: HistoryChannel(channelId: id, title: title),
      count: count,
      lastWatched: DateTime.utc(2026, 4, 12),
    );

Subscription _sub(String id, String title) => Subscription(
  channelId: id,
  channelUrl: 'http://www.youtube.com/channel/$id',
  channelTitle: title,
);

final _channels = [
  _watched('Alpha', id: 'UCa', count: 3),
  _watched('Beta', id: 'UCb', count: 2),
  _watched('Gamma', count: 1),
];

void main() {
  group('subscriptions', () {
    test('are matched to watched channels by their ID', () {
      final match = matchSubscriptions(_channels, [_sub('UCb', 'Beta')]);

      expect(match.subscribedKeys, {'UCb'});
      expect(match.unwatched, isEmpty);
    });

    test('a channel the history only names is matched by that name', () {
      final match = matchSubscriptions(_channels, [_sub('UCg', 'Gamma')]);

      expect(match.subscribedKeys, {'name:Gamma'});
      expect(match.unwatched, isEmpty);
    });

    test('never watched ones are listed by name', () {
      final match = matchSubscriptions(_channels, [
        _sub('UCz', 'zeta'),
        _sub('UCa', 'Alpha'),
        _sub('UCy', 'Epsilon'),
      ]);

      expect(match.subscribedKeys, {'UCa'});
      expect(
        [for (final c in match.unwatched) (c.channelId, c.title)],
        [('UCy', 'Epsilon'), ('UCz', 'zeta')],
      );
      expect(match.unwatched.first.channelUrl, contains('UCy'));
    });
  });

  group('the channel mask', () {
    List<String> shown(ChannelMask? mask) => [
      for (final (i, c) in _channels.indexed)
        if (mask == null || mask.allows(i)) c.channel.title,
    ];

    test('is none while nothing narrows the channels', () {
      expect(
        buildChannelMask(
          channels: _channels,
          subscribedKeys: const {'UCa'},
          subscription: SubscriptionFilter.all,
          selection: const ChannelSelection(),
        ),
        isNull,
      );
    });

    test('keeps only subscribed channels, or only the others', () {
      ChannelMask? mask(SubscriptionFilter filter) => buildChannelMask(
        channels: _channels,
        subscribedKeys: const {'UCa'},
        subscription: filter,
        selection: const ChannelSelection(),
      );

      expect(shown(mask(SubscriptionFilter.subscribed)), ['Alpha']);
      expect(shown(mask(SubscriptionFilter.notSubscribed)), ['Beta', 'Gamma']);
    });

    test('keeps the channels picked', () {
      final mask = buildChannelMask(
        channels: _channels,
        subscribedKeys: const {},
        subscription: SubscriptionFilter.all,
        selection: ChannelSelection(
          channels: {
            'UCb': _channels[1].channel,
            'name:Gamma': _channels[2].channel,
          },
        ),
      );

      expect(shown(mask), ['Beta', 'Gamma']);
    });

    test('picked channels must also pass the subscription filter', () {
      final mask = buildChannelMask(
        channels: _channels,
        subscribedKeys: const {'UCa'},
        subscription: SubscriptionFilter.subscribed,
        selection: ChannelSelection(
          channels: {'UCa': _channels[0].channel, 'UCb': _channels[1].channel},
        ),
      );

      expect(shown(mask), ['Alpha']);
    });

    const categories = {
      'UCa': CategoryPath('Gaming', 'Action game'),
      'UCb': CategoryPath('Lifestyle', 'Cooking'),
    };
    ChannelMask? byCategory(
      ChannelSelection selection, {
      SubscriptionFilter subscription = SubscriptionFilter.all,
    }) => buildChannelMask(
      channels: _channels,
      subscribedKeys: const {'UCa'},
      subscription: subscription,
      selection: selection,
      categoryOf: (key) => categories[key],
    );

    test('keeps the channels of the categories picked', () {
      expect(
        shown(
          byCategory(
            ChannelSelection(
              categories: {const CategoryPick.category('Gaming')},
            ),
          ),
        ),
        ['Alpha'],
      );
      expect(
        shown(
          byCategory(
            ChannelSelection(categories: {CategoryPick.uncategorized()}),
          ),
        ),
        ['Gamma'],
      );
    });

    test('keeps the channels picked and those of the categories picked', () {
      final mask = byCategory(
        ChannelSelection(
          channels: {'UCb': _channels[1].channel},
          categories: {const CategoryPick.uncategorized()},
        ),
      );

      expect(shown(mask), ['Beta', 'Gamma']);
    });

    test('channels of the categories picked must also pass the subscription '
        'filter', () {
      final mask = byCategory(
        ChannelSelection(
          categories: {
            const CategoryPick.category('Gaming'),
            const CategoryPick.category('Lifestyle'),
          },
        ),
        subscription: SubscriptionFilter.notSubscribed,
      );

      expect(shown(mask), ['Beta']);
    });

    test('masks that show the same channels are equal', () {
      ChannelMask? mask() => buildChannelMask(
        channels: _channels,
        subscribedKeys: const {'UCa'},
        subscription: SubscriptionFilter.subscribed,
        selection: const ChannelSelection(),
      );

      expect(mask(), mask());
      expect(mask().hashCode, mask().hashCode);
    });
  });

  test('a channel passes the filters on its own, as subscriptions never '
      'watched are checked', () {
    bool passes(SubscriptionFilter filter, {bool picked = true}) =>
        channelPasses(
          key: 'UCz',
          subscribed: true,
          subscription: filter,
          selection: picked
              ? const ChannelSelection()
              : const ChannelSelection(
                  channels: {'UCa': HistoryChannel(title: 'Alpha')},
                ),
        );

    expect(passes(SubscriptionFilter.all), isTrue);
    expect(passes(SubscriptionFilter.subscribed), isTrue);
    expect(passes(SubscriptionFilter.notSubscribed), isFalse);
    expect(passes(SubscriptionFilter.all, picked: false), isFalse);
  });

  test('picking categories picks something, and selections of the same '
      'channels and categories are equal', () {
    final picked = ChannelSelection(
      categories: {const CategoryPick.category('Gaming')},
    );

    expect(picked.isEmpty, isFalse);
    expect(
      picked,
      ChannelSelection(categories: {const CategoryPick.category('Gaming')}),
    );
    expect(picked, isNot(const ChannelSelection()));
  });
}
