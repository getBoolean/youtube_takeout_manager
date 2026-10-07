// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_engine.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where the loaded history is kept: the History worker, started on first
/// use, or in-process in tests.

@ProviderFor(historyEngine)
final historyEngineProvider = HistoryEngineProvider._();

/// Where the loaded history is kept: the History worker, started on first
/// use, or in-process in tests.

final class HistoryEngineProvider
    extends $FunctionalProvider<HistoryEngine, HistoryEngine, HistoryEngine>
    with $Provider<HistoryEngine> {
  /// Where the loaded history is kept: the History worker, started on first
  /// use, or in-process in tests.
  HistoryEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyEngineHash();

  @$internal
  @override
  $ProviderElement<HistoryEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HistoryEngine create(Ref ref) {
    return historyEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryEngine>(value),
    );
  }
}

String _$historyEngineHash() => r'9d3f59069cf8e52d19c424bda77615f1d6aa7179';
