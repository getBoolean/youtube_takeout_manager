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

String _$historyFiltersHash() => r'c9c699ece34b8da9915b57ad3935b29224a24b09';

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

/// The channels shown, the most watched first; searching finds them by name
/// first, then by the titles of videos watched from them.

@ProviderFor(filteredWatchedChannels)
final filteredWatchedChannelsProvider = FilteredWatchedChannelsProvider._();

/// The channels shown, the most watched first; searching finds them by name
/// first, then by the titles of videos watched from them.

final class FilteredWatchedChannelsProvider
    extends
        $FunctionalProvider<
          List<WatchedChannel>,
          List<WatchedChannel>,
          List<WatchedChannel>
        >
    with $Provider<List<WatchedChannel>> {
  /// The channels shown, the most watched first; searching finds them by name
  /// first, then by the titles of videos watched from them.
  FilteredWatchedChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredWatchedChannelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredWatchedChannelsHash();

  @$internal
  @override
  $ProviderElement<List<WatchedChannel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<WatchedChannel> create(Ref ref) {
    return filteredWatchedChannels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<WatchedChannel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<WatchedChannel>>(value),
    );
  }
}

String _$filteredWatchedChannelsHash() =>
    r'8882179922b867874f428872b7d022ddbeb30b42';
