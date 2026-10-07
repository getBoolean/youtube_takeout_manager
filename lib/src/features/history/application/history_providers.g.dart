// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The loaded history, or none while it loads.

@ProviderFor(loadedHistory)
final loadedHistoryProvider = LoadedHistoryProvider._();

/// The loaded history, or none while it loads.

final class LoadedHistoryProvider
    extends $FunctionalProvider<LoadedHistory, LoadedHistory, LoadedHistory>
    with $Provider<LoadedHistory> {
  /// The loaded history, or none while it loads.
  LoadedHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loadedHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loadedHistoryHash();

  @$internal
  @override
  $ProviderElement<LoadedHistory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoadedHistory create(Ref ref) {
    return loadedHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadedHistory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadedHistory>(value),
    );
  }
}

String _$loadedHistoryHash() => r'51ea5a423648bc55fd76f67dca8e3fe8636f8b3a';

/// The channels the selected takeout's account subscribes to, by channel ID.

@ProviderFor(historySubscriptions)
final historySubscriptionsProvider = HistorySubscriptionsProvider._();

/// The channels the selected takeout's account subscribes to, by channel ID.

final class HistorySubscriptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Subscription>>,
          Map<String, Subscription>,
          FutureOr<Map<String, Subscription>>
        >
    with
        $FutureModifier<Map<String, Subscription>>,
        $FutureProvider<Map<String, Subscription>> {
  /// The channels the selected takeout's account subscribes to, by channel ID.
  HistorySubscriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historySubscriptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historySubscriptionsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, Subscription>> create(Ref ref) {
    return historySubscriptions(ref);
  }
}

String _$historySubscriptionsHash() =>
    r'588bbbf199b0082a2e80b27318572f942ec44bd1';

/// Which watched channels are subscribed to, and the channels subscribed to
/// but never watched; none while the subscriptions load.

@ProviderFor(historySubscriptionMatch)
final historySubscriptionMatchProvider = HistorySubscriptionMatchProvider._();

/// Which watched channels are subscribed to, and the channels subscribed to
/// but never watched; none while the subscriptions load.

final class HistorySubscriptionMatchProvider
    extends
        $FunctionalProvider<
          SubscriptionMatch,
          SubscriptionMatch,
          SubscriptionMatch
        >
    with $Provider<SubscriptionMatch> {
  /// Which watched channels are subscribed to, and the channels subscribed to
  /// but never watched; none while the subscriptions load.
  HistorySubscriptionMatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historySubscriptionMatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historySubscriptionMatchHash();

  @$internal
  @override
  $ProviderElement<SubscriptionMatch> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubscriptionMatch create(Ref ref) {
    return historySubscriptionMatch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionMatch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionMatch>(value),
    );
  }
}

String _$historySubscriptionMatchHash() =>
    r'01d709dc754df96bdcf2896acb382edb3b9b1808';

/// Every channel the watched videos can be narrowed to, whatever's shown:
/// the watched ones, most watched first, then the ones subscribed to but
/// never watched, by name.

@ProviderFor(historyFilterChannels)
final historyFilterChannelsProvider = HistoryFilterChannelsProvider._();

/// Every channel the watched videos can be narrowed to, whatever's shown:
/// the watched ones, most watched first, then the ones subscribed to but
/// never watched, by name.

final class HistoryFilterChannelsProvider
    extends
        $FunctionalProvider<
          List<FilterChannel>,
          List<FilterChannel>,
          List<FilterChannel>
        >
    with $Provider<List<FilterChannel>> {
  /// Every channel the watched videos can be narrowed to, whatever's shown:
  /// the watched ones, most watched first, then the ones subscribed to but
  /// never watched, by name.
  HistoryFilterChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyFilterChannelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyFilterChannelsHash();

  @$internal
  @override
  $ProviderElement<List<FilterChannel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FilterChannel> create(Ref ref) {
    return historyFilterChannels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FilterChannel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FilterChannel>>(value),
    );
  }
}

String _$historyFilterChannelsHash() =>
    r'29dea637b263a425e2246ce3d479b4fbf1ed336e';

/// Each channel's category, by key, while categories are picked; null
/// otherwise, so categories arriving don't search again.

@ProviderFor(historyPickedCategoryOf)
final historyPickedCategoryOfProvider = HistoryPickedCategoryOfProvider._();

/// Each channel's category, by key, while categories are picked; null
/// otherwise, so categories arriving don't search again.

final class HistoryPickedCategoryOfProvider
    extends
        $FunctionalProvider<
          CategoryPath? Function(String key)?,
          CategoryPath? Function(String key)?,
          CategoryPath? Function(String key)?
        >
    with $Provider<CategoryPath? Function(String key)?> {
  /// Each channel's category, by key, while categories are picked; null
  /// otherwise, so categories arriving don't search again.
  HistoryPickedCategoryOfProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyPickedCategoryOfProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyPickedCategoryOfHash();

  @$internal
  @override
  $ProviderElement<CategoryPath? Function(String key)?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryPath? Function(String key)? create(Ref ref) {
    return historyPickedCategoryOf(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryPath? Function(String key)? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryPath? Function(String key)?>(
        value,
      ),
    );
  }
}

String _$historyPickedCategoryOfHash() =>
    r'7c3bff0b01580936b379dfd18fd10b9b915cc170';

/// Each channel's tags, by key, while tags are picked; null otherwise, so
/// tags arriving don't search again.

@ProviderFor(historyPickedTagsOf)
final historyPickedTagsOfProvider = HistoryPickedTagsOfProvider._();

/// Each channel's tags, by key, while tags are picked; null otherwise, so
/// tags arriving don't search again.

final class HistoryPickedTagsOfProvider
    extends
        $FunctionalProvider<
          List<String> Function(String key)?,
          List<String> Function(String key)?,
          List<String> Function(String key)?
        >
    with $Provider<List<String> Function(String key)?> {
  /// Each channel's tags, by key, while tags are picked; null otherwise, so
  /// tags arriving don't search again.
  HistoryPickedTagsOfProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyPickedTagsOfProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyPickedTagsOfHash();

  @$internal
  @override
  $ProviderElement<List<String> Function(String key)?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<String> Function(String key)? create(Ref ref) {
    return historyPickedTagsOf(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> Function(String key)? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String> Function(String key)?>(
        value,
      ),
    );
  }
}

String _$historyPickedTagsOfHash() =>
    r'8b032fe972ce0a05368c4b29db561f09438e7636';

/// The watched channels the channel filters show, or null when they narrow
/// nothing.

@ProviderFor(historyChannelMask)
final historyChannelMaskProvider = HistoryChannelMaskProvider._();

/// The watched channels the channel filters show, or null when they narrow
/// nothing.

final class HistoryChannelMaskProvider
    extends $FunctionalProvider<ChannelMask?, ChannelMask?, ChannelMask?>
    with $Provider<ChannelMask?> {
  /// The watched channels the channel filters show, or null when they narrow
  /// nothing.
  HistoryChannelMaskProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyChannelMaskProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyChannelMaskHash();

  @$internal
  @override
  $ProviderElement<ChannelMask?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChannelMask? create(Ref ref) {
    return historyChannelMask(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChannelMask? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChannelMask?>(value),
    );
  }
}

String _$historyChannelMaskHash() =>
    r'e82a9962e96068fcc1d1a937640d03af13b9b10f';

/// How many videos were watched from each watched channel, in the loaded
/// history's order, of the kinds of videos shown: Shorts and YouTube Music
/// as filtered. Counted by the History worker when filtered.

@ProviderFor(historyChannelWatchCounts)
final historyChannelWatchCountsProvider = HistoryChannelWatchCountsProvider._();

/// How many videos were watched from each watched channel, in the loaded
/// history's order, of the kinds of videos shown: Shorts and YouTube Music
/// as filtered. Counted by the History worker when filtered.

final class HistoryChannelWatchCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChannelWatchCounts>,
          ChannelWatchCounts,
          FutureOr<ChannelWatchCounts>
        >
    with
        $FutureModifier<ChannelWatchCounts>,
        $FutureProvider<ChannelWatchCounts> {
  /// How many videos were watched from each watched channel, in the loaded
  /// history's order, of the kinds of videos shown: Shorts and YouTube Music
  /// as filtered. Counted by the History worker when filtered.
  HistoryChannelWatchCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyChannelWatchCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyChannelWatchCountsHash();

  @$internal
  @override
  $FutureProviderElement<ChannelWatchCounts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ChannelWatchCounts> create(Ref ref) {
    return historyChannelWatchCounts(ref);
  }
}

String _$historyChannelWatchCountsHash() =>
    r'cbe3a0496ff373062d15cba7671bcec1dae06924';

/// Tells the History worker which videos are Shorts by the format fetched
/// for them, whenever those or the history change; answers how many
/// watched videos are Shorts, by their link or their format.

@ProviderFor(historyShorts)
final historyShortsProvider = HistoryShortsProvider._();

/// Tells the History worker which videos are Shorts by the format fetched
/// for them, whenever those or the history change; answers how many
/// watched videos are Shorts, by their link or their format.

final class HistoryShortsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Tells the History worker which videos are Shorts by the format fetched
  /// for them, whenever those or the history change; answers how many
  /// watched videos are Shorts, by their link or their format.
  HistoryShortsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyShortsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyShortsHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return historyShorts(ref);
  }
}

String _$historyShortsHash() => r'edf8f9cc911d8d6aed115c67e86f58e6d17a7476';

/// How many watched videos are known to be Shorts.

@ProviderFor(historyShortCount)
final historyShortCountProvider = HistoryShortCountProvider._();

/// How many watched videos are known to be Shorts.

final class HistoryShortCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// How many watched videos are known to be Shorts.
  HistoryShortCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyShortCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyShortCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return historyShortCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$historyShortCountHash() => r'd04d1c8fa42cd029055fd772ab2aaf03228f42b6';

/// What the history screen narrows the history to.

@ProviderFor(historyFilters)
final historyFiltersProvider = HistoryFiltersProvider._();

/// What the history screen narrows the history to.

final class HistoryFiltersProvider
    extends $FunctionalProvider<HistoryFilters, HistoryFilters, HistoryFilters>
    with $Provider<HistoryFilters> {
  /// What the history screen narrows the history to.
  HistoryFiltersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyFiltersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyFiltersHash();

  @$internal
  @override
  $ProviderElement<HistoryFilters> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HistoryFilters create(Ref ref) {
    return historyFilters(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryFilters value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryFilters>(value),
    );
  }
}

String _$historyFiltersHash() => r'ecac19d91e56f88e80ff4ce87af03e5aaf420724';

/// The history narrowed to the filters, by the History worker. A search
/// asked since replaces it: an answer to this one arriving after is never
/// used.

@ProviderFor(historySearch)
final historySearchProvider = HistorySearchProvider._();

/// The history narrowed to the filters, by the History worker. A search
/// asked since replaces it: an answer to this one arriving after is never
/// used.

final class HistorySearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<HistoryResults>,
          HistoryResults,
          FutureOr<HistoryResults>
        >
    with $FutureModifier<HistoryResults>, $FutureProvider<HistoryResults> {
  /// The history narrowed to the filters, by the History worker. A search
  /// asked since replaces it: an answer to this one arriving after is never
  /// used.
  HistorySearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: _searchOnce,
        name: r'historySearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historySearchHash();

  @$internal
  @override
  $FutureProviderElement<HistoryResults> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HistoryResults> create(Ref ref) {
    return historySearch(ref);
  }
}

String _$historySearchHash() => r'c41ee622e0a9bc06e643a6176b5c64301bcbc57d';

/// What's shown: everything when unfiltered, else the newest search's
/// results, the previous ones while a search is under way.

@ProviderFor(historyResults)
final historyResultsProvider = HistoryResultsProvider._();

/// What's shown: everything when unfiltered, else the newest search's
/// results, the previous ones while a search is under way.

final class HistoryResultsProvider
    extends $FunctionalProvider<HistoryResults, HistoryResults, HistoryResults>
    with $Provider<HistoryResults> {
  /// What's shown: everything when unfiltered, else the newest search's
  /// results, the previous ones while a search is under way.
  HistoryResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyResultsHash();

  @$internal
  @override
  $ProviderElement<HistoryResults> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HistoryResults create(Ref ref) {
    return historyResults(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryResults value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryResults>(value),
    );
  }
}

String _$historyResultsHash() => r'b2ad30f250ef201de36c07d4633972acb353699a';

/// The watched videos shown, by day, newest first. Entries are indices into
/// the history's watched videos.

@ProviderFor(watchDays)
final watchDaysProvider = WatchDaysProvider._();

/// The watched videos shown, by day, newest first. Entries are indices into
/// the history's watched videos.

final class WatchDaysProvider
    extends
        $FunctionalProvider<
          List<HistoryDay>,
          List<HistoryDay>,
          List<HistoryDay>
        >
    with $Provider<List<HistoryDay>> {
  /// The watched videos shown, by day, newest first. Entries are indices into
  /// the history's watched videos.
  WatchDaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchDaysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchDaysHash();

  @$internal
  @override
  $ProviderElement<List<HistoryDay>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<HistoryDay> create(Ref ref) {
    return watchDays(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HistoryDay> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HistoryDay>>(value),
    );
  }
}

String _$watchDaysHash() => r'56ec66de923854f5bb470545a0dbb8bfcc7435c9';

/// The watched videos shown, by month, newest first.

@ProviderFor(watchMonths)
final watchMonthsProvider = WatchMonthsProvider._();

/// The watched videos shown, by month, newest first.

final class WatchMonthsProvider
    extends
        $FunctionalProvider<
          List<HistoryDay>,
          List<HistoryDay>,
          List<HistoryDay>
        >
    with $Provider<List<HistoryDay>> {
  /// The watched videos shown, by month, newest first.
  WatchMonthsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchMonthsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchMonthsHash();

  @$internal
  @override
  $ProviderElement<List<HistoryDay>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<HistoryDay> create(Ref ref) {
    return watchMonths(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HistoryDay> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HistoryDay>>(value),
    );
  }
}

String _$watchMonthsHash() => r'29772fe189e95ca58bf7ae272d796d729a31e3fb';

/// The searches shown, by day, newest first. Entries are indices into the
/// history's searches.

@ProviderFor(searchDays)
final searchDaysProvider = SearchDaysProvider._();

/// The searches shown, by day, newest first. Entries are indices into the
/// history's searches.

final class SearchDaysProvider
    extends
        $FunctionalProvider<
          List<HistoryDay>,
          List<HistoryDay>,
          List<HistoryDay>
        >
    with $Provider<List<HistoryDay>> {
  /// The searches shown, by day, newest first. Entries are indices into the
  /// history's searches.
  SearchDaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchDaysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchDaysHash();

  @$internal
  @override
  $ProviderElement<List<HistoryDay>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<HistoryDay> create(Ref ref) {
    return searchDays(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HistoryDay> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HistoryDay>>(value),
    );
  }
}

String _$searchDaysHash() => r'6b1de2cb6eac9d08943c81f948f31f13ad05f59c';

/// The watched videos shown, by channel, with the channels subscribed to
/// but never watched that the filters let through: only while every kind of
/// watched video shows, and, searching, when their names match.

@ProviderFor(historyChannelGroups)
final historyChannelGroupsProvider = HistoryChannelGroupsProvider._();

/// The watched videos shown, by channel, with the channels subscribed to
/// but never watched that the filters let through: only while every kind of
/// watched video shows, and, searching, when their names match.

final class HistoryChannelGroupsProvider
    extends $FunctionalProvider<ChannelGroups, ChannelGroups, ChannelGroups>
    with $Provider<ChannelGroups> {
  /// The watched videos shown, by channel, with the channels subscribed to
  /// but never watched that the filters let through: only while every kind of
  /// watched video shows, and, searching, when their names match.
  HistoryChannelGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyChannelGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyChannelGroupsHash();

  @$internal
  @override
  $ProviderElement<ChannelGroups> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChannelGroups create(Ref ref) {
    return historyChannelGroups(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChannelGroups value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChannelGroups>(value),
    );
  }
}

String _$historyChannelGroupsHash() =>
    r'fa9d4ddffa581c17e00ec0d00a461704e88b77bb';

/// The watched videos shown grouped by channel, nested under the
/// categories picked; none while no category is.

@ProviderFor(historyCategoryNests)
final historyCategoryNestsProvider = HistoryCategoryNestsProvider._();

/// The watched videos shown grouped by channel, nested under the
/// categories picked; none while no category is.

final class HistoryCategoryNestsProvider
    extends
        $FunctionalProvider<
          List<CategoryNest>,
          List<CategoryNest>,
          List<CategoryNest>
        >
    with $Provider<List<CategoryNest>> {
  /// The watched videos shown grouped by channel, nested under the
  /// categories picked; none while no category is.
  HistoryCategoryNestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyCategoryNestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyCategoryNestsHash();

  @$internal
  @override
  $ProviderElement<List<CategoryNest>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CategoryNest> create(Ref ref) {
    return historyCategoryNests(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CategoryNest> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CategoryNest>>(value),
    );
  }
}

String _$historyCategoryNestsHash() =>
    r'6a8ad10fb521cd1296d533b73be88f7bc72c9e11';
