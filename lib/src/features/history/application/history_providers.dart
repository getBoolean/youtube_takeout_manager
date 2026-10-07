import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_format_providers.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../domain/category_nests.dart';
import '../domain/channel_groups.dart';
import '../domain/history_days.dart';
import '../data/history_engine.dart';
import '../domain/history_search.dart';
import '../domain/history_wire.dart';
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

/// How many videos were watched from each channel of [loaded], in its
/// order.
typedef ChannelWatchCounts = ({LoadedHistory loaded, List<int> counts});

/// How many videos were watched from each watched channel, in the loaded
/// history's order, of the kinds of videos shown: Shorts and YouTube Music
/// as filtered. Counted by the History worker when filtered.
@riverpod
Future<ChannelWatchCounts> historyChannelWatchCounts(Ref ref) async {
  final loaded = ref.watch(loadedHistoryProvider);
  final shorts = ref.watch(historyShortsFilterProvider);
  final music = ref.watch(historyMusicFilterProvider);
  if (shorts == ShowFilter.all && music == ShowFilter.all) {
    return (
      loaded: loaded,
      counts: [for (final watched in loaded.watchedChannels) watched.count],
    );
  }
  final engine = ref.watch(historyEngineProvider);
  // The worker is told first which videos are Shorts by their format.
  if (shorts != ShowFilter.all) await ref.watch(historyShortsProvider.future);
  return (
    loaded: loaded,
    counts: await engine.channelWatchCounts(shorts: shorts, music: music),
  );
}

/// Tells the History worker which videos are Shorts by the format fetched
/// for them, whenever those or the history change; answers how many
/// watched videos are Shorts, by their link or their format.
@riverpod
Future<int> historyShorts(Ref ref) async {
  ref.watch(loadedHistoryProvider);
  final formats = ref.watch(videoFormatsProvider).value ?? const {};
  return ref.watch(historyEngineProvider).setShortVideos([
    for (final MapEntry(key: videoId, value: format) in formats.entries)
      if (format.isShort) videoId,
  ]);
}

/// How many watched videos are known to be Shorts.
@riverpod
int historyShortCount(Ref ref) =>
    ref.watch(historyShortsProvider).value ??
    ref.watch(loadedHistoryProvider).shortCount;

/// What the history screen narrows the history to.
@riverpod
HistoryFilters historyFilters(Ref ref) {
  final shorts = ref.watch(historyShortsFilterProvider);
  return (
    query: ref.watch(historySearchQueryProvider),
    removedOnly: ref.watch(historyRemovedFilterProvider),
    shorts: shorts,
    // The History worker knows which are Shorts.
    shortWatches: null,
    music: ref.watch(historyMusicFilterProvider),
    channels: ref.watch(historyChannelMaskProvider),
  );
}

/// Each search asked of the History worker gets the next number.
var _searches = 0;

/// The history narrowed to the filters, by the History worker. A search
/// asked since replaces it: an answer to this one arriving after is never
/// used.
@riverpod
Future<HistoryResults> historySearch(Ref ref) async {
  final loaded = ref.watch(loadedHistoryProvider);
  final filters = ref.watch(historyFiltersProvider);
  if (isUnfiltered(filters)) return defaultResults(loaded);
  final engine = ref.watch(historyEngineProvider);
  // The worker is told first which videos are Shorts by their format, and
  // searched again when more are known.
  if (filters.shorts != ShowFilter.all) {
    await ref.watch(historyShortsProvider.future);
  }
  final matches = await engine.search(
    HistoryQuery(
      query: filters.query,
      removedOnly: filters.removedOnly,
      shorts: filters.shorts,
      music: filters.music,
      channelMask: filters.channels?.flags,
    ),
    ++_searches,
  );
  return (
    loaded: loaded,
    watchDays: matches.watchDays(),
    searchDays: matches.searchDays(),
    channelGroups: matches.channelGroups(loaded.watchedChannels),
  );
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

/// The watched videos shown grouped by channel, nested under the
/// categories picked; none while no category is.
@riverpod
List<CategoryNest> historyCategoryNests(Ref ref) {
  final picks = ref.watch(
    historyChannelSelectionProvider.select((s) => s.categories),
  );
  if (picks.isEmpty) return const [];
  final categories = ref.watch(channelCategoriesProvider).value ?? const {};
  return nestByCategory(
    ref.watch(historyChannelGroupsProvider).groups,
    picks: picks,
    categoryOf: (key) => categories[key]?.path,
  );
}
