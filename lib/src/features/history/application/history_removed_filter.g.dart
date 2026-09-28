// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_removed_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the history screen shows only entries a newer takeout no longer
/// had, removed from YouTube's history.

@ProviderFor(HistoryRemovedFilter)
final historyRemovedFilterProvider = HistoryRemovedFilterProvider._();

/// Whether the history screen shows only entries a newer takeout no longer
/// had, removed from YouTube's history.
final class HistoryRemovedFilterProvider
    extends $NotifierProvider<HistoryRemovedFilter, bool> {
  /// Whether the history screen shows only entries a newer takeout no longer
  /// had, removed from YouTube's history.
  HistoryRemovedFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyRemovedFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyRemovedFilterHash();

  @$internal
  @override
  HistoryRemovedFilter create() => HistoryRemovedFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$historyRemovedFilterHash() =>
    r'4801be9821c10650b3c383aeaef7417d6b1c1e2e';

/// Whether the history screen shows only entries a newer takeout no longer
/// had, removed from YouTube's history.

abstract class _$HistoryRemovedFilter extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
