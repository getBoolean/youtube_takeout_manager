import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../domain/channel_groups.dart';
import '../domain/history_days.dart';
import '../domain/history_search.dart';
import '../domain/loaded_history.dart';
import '../domain/watch_filters.dart';
import 'history_channel_selection.dart';
import 'history_removed_filter.dart';
import 'history_search_query.dart';
import 'takeout_history_notifier.dart';
import 'watch_filter_providers.dart';

part 'history_providers.g.dart';

/// The loaded history, or none while it loads.
@riverpod
LoadedHistory loadedHistory(Ref ref) =>
    ref.watch(takeoutHistoryProvider).value ?? LoadedHistory.empty;

/// The channels the selected takeout's account subscribes to, by channel ID.
@riverpod
Future<Map<String, Subscription>> historySubscriptions(Ref ref) async =>
    (await ref.watch(takeoutProvider.future))?.data.subscriptionsByChannelId ??
    const {};

/// Which watched channels are subscribed to, and the channels subscribed to
/// but never watched; none while the subscriptions load.
@riverpod
SubscriptionMatch historySubscriptionMatch(Ref ref) => matchSubscriptions(
  ref.watch(loadedHistoryProvider).watchedChannels,
  (ref.watch(historySubscriptionsProvider).value ?? const {}).values,
);

/// Every channel the watched videos can be narrowed to, whatever's shown:
/// the watched ones, most watched first, then the ones subscribed to but
/// never watched, by name.
@riverpod
List<FilterChannel> historyFilterChannels(Ref ref) {
  final channels = ref.watch(loadedHistoryProvider).watchedChannels;
  final match = ref.watch(historySubscriptionMatchProvider);
  return [
    for (final watched in channels)
      (
        channel: watched.channel,
        count: watched.count,
        subscribed: match.subscribedKeys.contains(watched.channel.key),
      ),
    for (final channel in match.unwatched)
      (channel: channel, count: 0, subscribed: true),
  ];
}

/// The watched channels the channel filters show, or null when they narrow
/// nothing.
@riverpod
ChannelMask? historyChannelMask(Ref ref) => buildChannelMask(
  channels: ref.watch(loadedHistoryProvider).watchedChannels,
  subscribedKeys: ref.watch(
    historySubscriptionMatchProvider.select((m) => m.subscribedKeys),
  ),
  subscription: ref.watch(historySubscriptionFilterProvider),
  selection: ref.watch(historyChannelSelectionProvider),
);

/// What the history screen narrows the history to.
@riverpod
HistoryFilters historyFilters(Ref ref) => (
  query: ref.watch(historySearchQueryProvider),
  removedOnly: ref.watch(historyRemovedFilterProvider),
  shorts: ref.watch(historyShortsFilterProvider),
  music: ref.watch(historyMusicFilterProvider),
  channels: ref.watch(historyChannelMaskProvider),
);

/// The history narrowed to the filters, worked out a slice at a time
/// between frames so the screen keeps moving; a newer search stops it.
@riverpod
Future<HistoryResults> historySearch(Ref ref) async {
  final loaded = ref.watch(loadedHistoryProvider);
  final filters = ref.watch(historyFiltersProvider);
  if (isUnfiltered(filters)) return defaultResults(loaded);
  final results = await searchHistory(
    loaded,
    filters,
    pause: () => Future<void>.delayed(Duration.zero),
    cancelled: () => !ref.mounted,
  );
  // Only null when replaced, and then nothing reads it.
  return results ?? defaultResults(loaded);
}

/// What's shown: everything when unfiltered, else the newest search's
/// results, the previous ones while a search is under way.
@riverpod
HistoryResults historyResults(Ref ref) {
  final loaded = ref.watch(loadedHistoryProvider);
  if (isUnfiltered(ref.watch(historyFiltersProvider))) {
    return defaultResults(loaded);
  }
  final results = ref.watch(historySearchProvider).value;
  // Results for a history since replaced would point at the wrong entries.
  return results != null && identical(results.loaded, loaded)
      ? results
      : defaultResults(loaded);
}

/// The watched videos shown, by day, newest first. Entries are indices into
/// the history's watched videos.
@riverpod
List<HistoryDay> watchDays(Ref ref) =>
    ref.watch(historyResultsProvider.select((r) => r.watchDays));

/// The watched videos shown, by month, newest first.
@riverpod
List<HistoryDay> watchMonths(Ref ref) => monthsOf(ref.watch(watchDaysProvider));

/// The searches shown, by day, newest first. Entries are indices into the
/// history's searches.
@riverpod
List<HistoryDay> searchDays(Ref ref) =>
    ref.watch(historyResultsProvider.select((r) => r.searchDays));

/// The watched videos shown, by channel, with the channels subscribed to
/// but never watched that the filters let through: only while every kind of
/// watched video shows, and, searching, when their names match.
@riverpod
ChannelGroups historyChannelGroups(Ref ref) {
  final groups = ref.watch(
    historyResultsProvider.select((r) => r.channelGroups),
  );
  final unwatched = ref.watch(
    historySubscriptionMatchProvider.select((m) => m.unwatched),
  );
  final subscription = ref.watch(historySubscriptionFilterProvider);
  if (unwatched.isEmpty ||
      ref.watch(historyRemovedFilterProvider) ||
      ref.watch(historyShortsFilterProvider) == ShowFilter.only ||
      ref.watch(historyMusicFilterProvider) == ShowFilter.only ||
      subscription == SubscriptionFilter.notSubscribed) {
    return groups;
  }
  final selection = ref.watch(historyChannelSelectionProvider);
  final query = foldForSearch(ref.watch(historySearchQueryProvider));
  return groups.withUnwatched([
    for (final channel in unwatched)
      if (channelPasses(
            key: channel.key,
            subscribed: true,
            subscription: subscription,
            selection: selection,
          ) &&
          (query.isEmpty || foldForSearch(channel.title).contains(query)))
        channel,
  ]);
}
