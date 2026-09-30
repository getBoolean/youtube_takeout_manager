// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorization_progress.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How far along categorizing channels is.

@ProviderFor(CategorizationProgress)
final categorizationProgressProvider = CategorizationProgressProvider._();

/// How far along categorizing channels is.
final class CategorizationProgressProvider
    extends
        $NotifierProvider<
          CategorizationProgress,
          ({int done, bool running, int total})
        > {
  /// How far along categorizing channels is.
  CategorizationProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categorizationProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categorizationProgressHash();

  @$internal
  @override
  CategorizationProgress create() => CategorizationProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int done, bool running, int total}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({int done, bool running, int total})>(value),
    );
  }
}

String _$categorizationProgressHash() =>
    r'597f0eff48ff6db2c8f15d1550ecfc6baa312b8e';

/// How far along categorizing channels is.

abstract class _$CategorizationProgress
    extends $Notifier<({int done, bool running, int total})> {
  ({int done, bool running, int total}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({int done, bool running, int total}),
              ({int done, bool running, int total})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({int done, bool running, int total}),
                ({int done, bool running, int total})
              >,
              ({int done, bool running, int total}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
