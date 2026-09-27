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
    extends $FunctionalProvider<TakeoutHistory, TakeoutHistory, TakeoutHistory>
    with $Provider<TakeoutHistory> {
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
  $ProviderElement<TakeoutHistory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TakeoutHistory create(Ref ref) {
    return loadedHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TakeoutHistory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TakeoutHistory>(value),
    );
  }
}

String _$loadedHistoryHash() => r'5fe0ef80116bfa60b83f6c3a7123542129dd19da';

/// The local day of each watch, worked out once per history.

@ProviderFor(watchDayKeys)
final watchDayKeysProvider = WatchDayKeysProvider._();

/// The local day of each watch, worked out once per history.

final class WatchDayKeysProvider
    extends $FunctionalProvider<List<int>, List<int>, List<int>>
    with $Provider<List<int>> {
  /// The local day of each watch, worked out once per history.
  WatchDayKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchDayKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchDayKeysHash();

  @$internal
  @override
  $ProviderElement<List<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<int> create(Ref ref) {
    return watchDayKeys(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<int>>(value),
    );
  }
}

String _$watchDayKeysHash() => r'894e53cc914c6c145de600ce3da2e45cb3191565';

/// The local day of each search, worked out once per history.

@ProviderFor(searchDayKeys)
final searchDayKeysProvider = SearchDayKeysProvider._();

/// The local day of each search, worked out once per history.

final class SearchDayKeysProvider
    extends $FunctionalProvider<List<int>, List<int>, List<int>>
    with $Provider<List<int>> {
  /// The local day of each search, worked out once per history.
  SearchDayKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchDayKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchDayKeysHash();

  @$internal
  @override
  $ProviderElement<List<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<int> create(Ref ref) {
    return searchDayKeys(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<int>>(value),
    );
  }
}

String _$searchDayKeysHash() => r'1c049be54eed4737d569849fcf524f52dffe40b6';

/// The watches that match the search and channel filter, by day, newest
/// first. Entries are indices into the history's watches.

@ProviderFor(watchDays)
final watchDaysProvider = WatchDaysProvider._();

/// The watches that match the search and channel filter, by day, newest
/// first. Entries are indices into the history's watches.

final class WatchDaysProvider
    extends
        $FunctionalProvider<
          List<HistoryDay>,
          List<HistoryDay>,
          List<HistoryDay>
        >
    with $Provider<List<HistoryDay>> {
  /// The watches that match the search and channel filter, by day, newest
  /// first. Entries are indices into the history's watches.
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

String _$watchDaysHash() => r'ac8717b51e39f5a48df173e13c5fd59d436585a5';

/// The searches that match the search, by day, newest first. Entries are
/// indices into the history's searches.

@ProviderFor(searchDays)
final searchDaysProvider = SearchDaysProvider._();

/// The searches that match the search, by day, newest first. Entries are
/// indices into the history's searches.

final class SearchDaysProvider
    extends
        $FunctionalProvider<
          List<HistoryDay>,
          List<HistoryDay>,
          List<HistoryDay>
        >
    with $Provider<List<HistoryDay>> {
  /// The searches that match the search, by day, newest first. Entries are
  /// indices into the history's searches.
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

String _$searchDaysHash() => r'fc9197cbb5d8db0e3ac8f163523942bfda9d278f';

/// Every channel videos were watched from, the most watched first.

@ProviderFor(watchedChannels)
final watchedChannelsProvider = WatchedChannelsProvider._();

/// Every channel videos were watched from, the most watched first.

final class WatchedChannelsProvider
    extends
        $FunctionalProvider<
          List<WatchedChannel>,
          List<WatchedChannel>,
          List<WatchedChannel>
        >
    with $Provider<List<WatchedChannel>> {
  /// Every channel videos were watched from, the most watched first.
  WatchedChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchedChannelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchedChannelsHash();

  @$internal
  @override
  $ProviderElement<List<WatchedChannel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<WatchedChannel> create(Ref ref) {
    return watchedChannels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<WatchedChannel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<WatchedChannel>>(value),
    );
  }
}

String _$watchedChannelsHash() => r'4dbb5a34b3099f3dc41cea75c51983469798ebe5';

/// The [watchedChannelsProvider] whose names match the search.

@ProviderFor(filteredWatchedChannels)
final filteredWatchedChannelsProvider = FilteredWatchedChannelsProvider._();

/// The [watchedChannelsProvider] whose names match the search.

final class FilteredWatchedChannelsProvider
    extends
        $FunctionalProvider<
          List<WatchedChannel>,
          List<WatchedChannel>,
          List<WatchedChannel>
        >
    with $Provider<List<WatchedChannel>> {
  /// The [watchedChannelsProvider] whose names match the search.
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
    r'b0439444dbaa9870e8c38b627a071e7191cd97b6';
