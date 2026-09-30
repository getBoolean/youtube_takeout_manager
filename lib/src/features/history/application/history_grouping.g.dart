// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_grouping.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How the history screen groups the watched videos now.

@ProviderFor(HistoryGroupingNotifier)
final historyGroupingProvider = HistoryGroupingNotifierProvider._();

/// How the history screen groups the watched videos now.
final class HistoryGroupingNotifierProvider
    extends $NotifierProvider<HistoryGroupingNotifier, HistoryGrouping> {
  /// How the history screen groups the watched videos now.
  HistoryGroupingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyGroupingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyGroupingNotifierHash();

  @$internal
  @override
  HistoryGroupingNotifier create() => HistoryGroupingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryGrouping value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryGrouping>(value),
    );
  }
}

String _$historyGroupingNotifierHash() =>
    r'e3cdd93a69309d69cbbd255346b3b03ad84a2c9e';

/// How the history screen groups the watched videos now.

abstract class _$HistoryGroupingNotifier extends $Notifier<HistoryGrouping> {
  HistoryGrouping build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HistoryGrouping, HistoryGrouping>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryGrouping, HistoryGrouping>,
              HistoryGrouping,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
