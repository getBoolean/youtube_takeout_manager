import 'package:flutter/foundation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

import 'watched_channels.dart';

/// Which channels are shown by whether they're subscribed to.
enum SubscriptionFilter { all, subscribed, notSubscribed }

/// Whether some kind of watched video, such as Shorts, is shown with the
/// rest, alone, or not at all.
enum ShowFilter { all, only, hide }

/// The channels picked to narrow the watched videos to, by
/// [HistoryChannel.key]; none picked narrows nothing.
@immutable
class ChannelSelection {
  final Map<String, HistoryChannel> channels;

  const ChannelSelection({this.channels = const {}});

  bool get isEmpty => channels.isEmpty;

  bool contains(String key) => channels.containsKey(key);

  @override
  bool operator ==(Object other) =>
      other is ChannelSelection &&
      setEquals(other.channels.keys.toSet(), channels.keys.toSet());

  @override
  int get hashCode => Object.hashAllUnordered(channels.keys);
}

/// Which of the history's watched channels are shown: one flag per channel,
/// in the order the loaded history lists them. Equal when they show the
/// same channels, so a filter that ends up the same doesn't search again.
@immutable
class ChannelMask {
  final Uint8List _shown;

  const ChannelMask(this._shown);

  /// Whether the channel at [channelIndex] is shown; videos without a
  /// channel (-1) never are.
  bool allows(int channelIndex) =>
      channelIndex >= 0 &&
      channelIndex < _shown.length &&
      _shown[channelIndex] != 0;

  @override
  bool operator ==(Object other) =>
      other is ChannelMask && listEquals(other._shown, _shown);

  @override
  int get hashCode => Object.hashAll(_shown);
}

/// Which of the history's watched videos have something, such as being a
/// Short: one flag per video, in the history's order. Equal when they flag
/// the same videos.
@immutable
class WatchMask {
  final Uint8List _flags;

  const WatchMask(this._flags);

  bool allows(int watchIndex) =>
      watchIndex < _flags.length && _flags[watchIndex] != 0;

  /// How many are flagged.
  int get count => _flags.fold(0, (sum, flag) => sum + (flag == 0 ? 0 : 1));

  @override
  bool operator ==(Object other) =>
      other is WatchMask && listEquals(other._flags, _flags);

  @override
  int get hashCode => Object.hashAll(_flags);
}

/// Whether the channel [key] passes the channel filters, being [subscribed]
/// or not: the subscription filter, and, when channels are picked, being one
/// of them.
bool channelPasses({
  required String key,
  required bool subscribed,
  required SubscriptionFilter subscription,
  required ChannelSelection selection,
}) =>
    switch (subscription) {
      SubscriptionFilter.all => true,
      SubscriptionFilter.subscribed => subscribed,
      SubscriptionFilter.notSubscribed => !subscribed,
    } &&
    (selection.isEmpty || selection.contains(key));

/// The channels of [channels] that pass the filters, or null when the
/// filters narrow nothing. [subscribedKeys] are the keys of the channels
/// subscribed to.
ChannelMask? buildChannelMask({
  required List<WatchedChannel> channels,
  required Set<String> subscribedKeys,
  required SubscriptionFilter subscription,
  required ChannelSelection selection,
}) {
  if (subscription == SubscriptionFilter.all && selection.isEmpty) return null;
  final shown = Uint8List(channels.length);
  for (final (i, watched) in channels.indexed) {
    final key = watched.channel.key;
    if (channelPasses(
      key: key,
      subscribed: subscribedKeys.contains(key),
      subscription: subscription,
      selection: selection,
    )) {
      shown[i] = 1;
    }
  }
  return ChannelMask(shown);
}

/// A channel that can be picked to narrow the watched videos to: how many
/// videos were watched from it, and whether it's subscribed to.
typedef FilterChannel = ({HistoryChannel channel, int count, bool subscribed});

/// The watched channels subscribed to, by [HistoryChannel.key], and the
/// channels subscribed to but never watched, by name.
typedef SubscriptionMatch = ({
  Set<String> subscribedKeys,
  List<HistoryChannel> unwatched,
});

/// Matches [subscriptions] to the [watched] channels: by channel ID, else,
/// for a channel the history only names, by that exact name among the
/// subscriptions no watched channel has the ID of.
SubscriptionMatch matchSubscriptions(
  List<WatchedChannel> watched,
  Iterable<Subscription> subscriptions,
) {
  final watchedIds = {for (final w in watched) ?w.channel.channelId};
  final nameOnly = {
    for (final w in watched)
      if (w.channel.channelId == null) w.channel.title: w.channel.key,
  };
  final subscribedKeys = <String>{};
  final unwatched = <HistoryChannel>[];
  for (final sub in subscriptions) {
    if (watchedIds.contains(sub.channelId)) {
      subscribedKeys.add(sub.channelId);
    } else if (nameOnly[sub.channelTitle] case final key?) {
      subscribedKeys.add(key);
    } else {
      unwatched.add(
        HistoryChannel(
          channelId: sub.channelId,
          title: sub.channelTitle,
          channelUrl: sub.channelUrl,
        ),
      );
    }
  }
  unwatched.sort(
    (a, b) => foldForSearch(a.title).compareTo(foldForSearch(b.title)),
  );
  return (subscribedKeys: subscribedKeys, unwatched: unwatched);
}
