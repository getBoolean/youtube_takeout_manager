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
    r'7d1e8486167cc00503dc2596836032fee7f14a5f';

/// How many videos were watched from each watched channel, in the loaded
/// history's order, of the kinds of videos shown: Shorts and YouTube Music
/// as filtered.

@ProviderFor(historyChannelWatchCounts)
final historyChannelWatchCountsProvider = HistoryChannelWatchCountsProvider._();

/// How many videos were watched from each watched channel, in the loaded
/// history's order, of the kinds of videos shown: Shorts and YouTube Music
/// as filtered.

final class HistoryChannelWatchCountsProvider
    extends $FunctionalProvider<List<int>, List<int>, List<int>>
    with $Provider<List<int>> {
  /// How many videos were watched from each watched channel, in the loaded
  /// history's order, of the kinds of videos shown: Shorts and YouTube Music
  /// as filtered.
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
  $ProviderElement<List<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<int> create(Ref ref) {
    return historyChannelWatchCounts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<int>>(value),
    );
  }
}

String _$historyChannelWatchCountsHash() =>
    r'2b112964ffe7fca8d5d88e643256e6fc2382fdee';

/// Which watched videos are Shorts: watched through a Shorts link, or
/// short and tall by the format fetched for them.

@ProviderFor(historyShortWatches)
final historyShortWatchesProvider = HistoryShortWatchesProvider._();

/// Which watched videos are Shorts: watched through a Shorts link, or
/// short and tall by the format fetched for them.

final class HistoryShortWatchesProvider
    extends $FunctionalProvider<WatchMask, WatchMask, WatchMask>
    with $Provider<WatchMask> {
  /// Which watched videos are Shorts: watched through a Shorts link, or
  /// short and tall by the format fetched for them.
  HistoryShortWatchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyShortWatchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyShortWatchesHash();

  @$internal
  @override
  $ProviderElement<WatchMask> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchMask create(Ref ref) {
    return historyShortWatches(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchMask value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchMask>(value),
    );
  }
}

String _$historyShortWatchesHash() =>
    r'550b9e856f3b3d25db36b7afe941ff0ab8d124f8';

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

String _$historyShortCountHash() => r'12958f9dc169ed1d0d98b55a3b1d723e207468a2';

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

String _$historyFiltersHash() => r'0b04e407d7e4524b5567dccda39e3480f401fab5';

/// The history narrowed to the filters, worked out a slice at a time
/// between frames so the screen keeps moving; a newer search stops it.

@ProviderFor(historySearch)
final historySearchProvider = HistorySearchProvider._();

/// The history narrowed to the filters, worked out a slice at a time
/// between frames so the screen keeps moving; a newer search stops it.

final class HistorySearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<HistoryResults>,
          HistoryResults,
          FutureOr<HistoryResults>
        >
    with $FutureModifier<HistoryResults>, $FutureProvider<HistoryResults> {
  /// The history narrowed to the filters, worked out a slice at a time
  /// between frames so the screen keeps moving; a newer search stops it.
  HistorySearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
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

String _$historySearchHash() => r'ab03545424dcff49dc04ffd7c6dd18b0111219bb';

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
    r'b9866c876d7950c88ac22563e0948a4902f879e1';

/// The watched videos shown, by the category of their channels, with the
/// channels subscribed to but never watched as [historyChannelGroups] has
/// them.

@ProviderFor(historyCategoryGroups)
final historyCategoryGroupsProvider = HistoryCategoryGroupsProvider._();

/// The watched videos shown, by the category of their channels, with the
/// channels subscribed to but never watched as [historyChannelGroups] has
/// them.

final class HistoryCategoryGroupsProvider
    extends $FunctionalProvider<CategoryGroups, CategoryGroups, CategoryGroups>
    with $Provider<CategoryGroups> {
  /// The watched videos shown, by the category of their channels, with the
  /// channels subscribed to but never watched as [historyChannelGroups] has
  /// them.
  HistoryCategoryGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyCategoryGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyCategoryGroupsHash();

  @$internal
  @override
  $ProviderElement<CategoryGroups> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CategoryGroups create(Ref ref) {
    return historyCategoryGroups(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryGroups value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryGroups>(value),
    );
  }
}

String _$historyCategoryGroupsHash() =>
    r'801c4bca15ed525e19895bf861e93c22563e9de7';
