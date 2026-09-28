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

/// The watched videos that match the search and filters, by day,
/// newest first. Entries are indices into the history's watched videos.

@ProviderFor(watchDays)
final watchDaysProvider = WatchDaysProvider._();

/// The watched videos that match the search and filters, by day,
/// newest first. Entries are indices into the history's watched videos.

final class WatchDaysProvider
    extends
        $FunctionalProvider<
          List<HistoryDay>,
          List<HistoryDay>,
          List<HistoryDay>
        >
    with $Provider<List<HistoryDay>> {
  /// The watched videos that match the search and filters, by day,
  /// newest first. Entries are indices into the history's watched videos.
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

String _$watchDaysHash() => r'213717175a1434775901ae1e3cdffa5a778acfd9';

/// The searches that match the search and the Removed filter, by day,
/// newest first. Entries are indices into the history's searches.

@ProviderFor(searchDays)
final searchDaysProvider = SearchDaysProvider._();

/// The searches that match the search and the Removed filter, by day,
/// newest first. Entries are indices into the history's searches.

final class SearchDaysProvider
    extends
        $FunctionalProvider<
          List<HistoryDay>,
          List<HistoryDay>,
          List<HistoryDay>
        >
    with $Provider<List<HistoryDay>> {
  /// The searches that match the search and the Removed filter, by day,
  /// newest first. Entries are indices into the history's searches.
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

String _$searchDaysHash() => r'5e82223c9087a5eb1ddf2a6ba5b4f8737eac7b8e';

/// The channels videos were watched from, the most watched first. A search
/// finds channels by name first, then those with videos whose titles match,
/// counting only those.

@ProviderFor(filteredWatchedChannels)
final filteredWatchedChannelsProvider = FilteredWatchedChannelsProvider._();

/// The channels videos were watched from, the most watched first. A search
/// finds channels by name first, then those with videos whose titles match,
/// counting only those.

final class FilteredWatchedChannelsProvider
    extends
        $FunctionalProvider<
          List<WatchedChannel>,
          List<WatchedChannel>,
          List<WatchedChannel>
        >
    with $Provider<List<WatchedChannel>> {
  /// The channels videos were watched from, the most watched first. A search
  /// finds channels by name first, then those with videos whose titles match,
  /// counting only those.
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
    r'10516aa2216ecf54595f71f31f3f8a0497f93e7b';
