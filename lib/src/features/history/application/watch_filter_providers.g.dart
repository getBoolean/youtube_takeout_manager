// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_filter_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the history screen's watched videos are narrowed to channels
/// subscribed to, or to the others.

@ProviderFor(HistorySubscriptionFilter)
final historySubscriptionFilterProvider = HistorySubscriptionFilterProvider._();

/// Whether the history screen's watched videos are narrowed to channels
/// subscribed to, or to the others.
final class HistorySubscriptionFilterProvider
    extends $NotifierProvider<HistorySubscriptionFilter, SubscriptionFilter> {
  /// Whether the history screen's watched videos are narrowed to channels
  /// subscribed to, or to the others.
  HistorySubscriptionFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historySubscriptionFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historySubscriptionFilterHash();

  @$internal
  @override
  HistorySubscriptionFilter create() => HistorySubscriptionFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionFilter>(value),
    );
  }
}

String _$historySubscriptionFilterHash() =>
    r'dcc84e927547c8d37a2f3c71cfa0ab309ed4ebef';

/// Whether the history screen's watched videos are narrowed to channels
/// subscribed to, or to the others.

abstract class _$HistorySubscriptionFilter
    extends $Notifier<SubscriptionFilter> {
  SubscriptionFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SubscriptionFilter, SubscriptionFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SubscriptionFilter, SubscriptionFilter>,
              SubscriptionFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether the history screen's Shorts are shown, alone, or hidden.

@ProviderFor(HistoryShortsFilter)
final historyShortsFilterProvider = HistoryShortsFilterProvider._();

/// Whether the history screen's Shorts are shown, alone, or hidden.
final class HistoryShortsFilterProvider
    extends $NotifierProvider<HistoryShortsFilter, ShowFilter> {
  /// Whether the history screen's Shorts are shown, alone, or hidden.
  HistoryShortsFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyShortsFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyShortsFilterHash();

  @$internal
  @override
  HistoryShortsFilter create() => HistoryShortsFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShowFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShowFilter>(value),
    );
  }
}

String _$historyShortsFilterHash() =>
    r'c68027af8abaca425375b0b02635cabb8e84735f';

/// Whether the history screen's Shorts are shown, alone, or hidden.

abstract class _$HistoryShortsFilter extends $Notifier<ShowFilter> {
  ShowFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ShowFilter, ShowFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShowFilter, ShowFilter>,
              ShowFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether the history screen's videos watched on YouTube Music are shown,
/// alone, or hidden.

@ProviderFor(HistoryMusicFilter)
final historyMusicFilterProvider = HistoryMusicFilterProvider._();

/// Whether the history screen's videos watched on YouTube Music are shown,
/// alone, or hidden.
final class HistoryMusicFilterProvider
    extends $NotifierProvider<HistoryMusicFilter, ShowFilter> {
  /// Whether the history screen's videos watched on YouTube Music are shown,
  /// alone, or hidden.
  HistoryMusicFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyMusicFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyMusicFilterHash();

  @$internal
  @override
  HistoryMusicFilter create() => HistoryMusicFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShowFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShowFilter>(value),
    );
  }
}

String _$historyMusicFilterHash() =>
    r'4273671d67d25edabc504078f31f564907ffb0f1';

/// Whether the history screen's videos watched on YouTube Music are shown,
/// alone, or hidden.

abstract class _$HistoryMusicFilter extends $Notifier<ShowFilter> {
  ShowFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ShowFilter, ShowFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShowFilter, ShowFilter>,
              ShowFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
