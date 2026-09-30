import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_format_providers.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../domain/category_groups.dart';
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

/// Each channel's category, by key, while categories are picked; null
/// otherwise, so categories arriving don't search again.
@riverpod
CategoryPath? Function(String key)? historyPickedCategoryOf(Ref ref) {
  if (ref.watch(
    historyChannelSelectionProvider.select((s) => s.categories.isEmpty),
  )) {
    return null;
  }
  final categories = ref.watch(channelCategoriesProvider).value ?? const {};
  return (key) => categories[key]?.path;
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
  categoryOf: ref.watch(historyPickedCategoryOfProvider),
);

/// How many videos were watched from each watched channel, in the loaded
/// history's order, of the kinds of videos shown: Shorts and YouTube Music
/// as filtered.
@riverpod
List<int> historyChannelWatchCounts(Ref ref) {
  final shorts = ref.watch(historyShortsFilterProvider);
  return countChannelWatches(
    ref.watch(loadedHistoryProvider),
    shorts: shorts,
    shortWatches: shorts == ShowFilter.all
        ? null
        : ref.watch(historyShortWatchesProvider),
    music: ref.watch(historyMusicFilterProvider),
  );
}

/// Which watched videos are Shorts: watched through a Shorts link, or
/// short and tall by the format fetched for them.
@riverpod
WatchMask historyShortWatches(Ref ref) {
  final watches = ref.watch(loadedHistoryProvider).history.watches;
  final formats = ref.watch(videoFormatsProvider).value ?? const {};
  final flags = Uint8List(watches.length);
  for (final (i, watch) in watches.indexed) {
    if (watch.isShort || (formats[watch.videoId]?.isShort ?? false)) {
      flags[i] = 1;
    }
  }
  return WatchMask(flags);
}

/// How many watched videos are known to be Shorts.
@riverpod
int historyShortCount(Ref ref) => ref.watch(historyShortWatchesProvider).count;

/// What the history screen narrows the history to.
@riverpod
HistoryFilters historyFilters(Ref ref) {
  final shorts = ref.watch(historyShortsFilterProvider);
  return (
    query: ref.watch(historySearchQueryProvider),
    removedOnly: ref.watch(historyRemovedFilterProvider),
    shorts: shorts,
    // Only looked at while Shorts are filtered, so formats arriving don't
    // search again otherwise.
    shortWatches: shorts == ShowFilter.all
        ? null
        : ref.watch(historyShortWatchesProvider),
    music: ref.watch(historyMusicFilterProvider),
    channels: ref.watch(historyChannelMaskProvider),
  );
}

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
  final categoryOf = ref.watch(historyPickedCategoryOfProvider);
  final query = foldForSearch(ref.watch(historySearchQueryProvider));
  return groups.withUnwatched([
    for (final channel in unwatched)
      if (channelPasses(
            key: channel.key,
            subscribed: true,
            subscription: subscription,
            selection: selection,
            category: categoryOf?.call(channel.key),
          ) &&
          (query.isEmpty || foldForSearch(channel.title).contains(query)))
        channel,
  ]);
}

/// The watched videos shown, by the category of their channels, with the
/// channels subscribed to but never watched as [historyChannelGroups] has
/// them.
@riverpod
CategoryGroups historyCategoryGroups(Ref ref) {
  final categories = ref.watch(channelCategoriesProvider).value ?? const {};
  return groupByCategory(
    ref.watch(historyChannelGroupsProvider),
    categoryOf: (key) => categories[key]?.path,
  );
}
