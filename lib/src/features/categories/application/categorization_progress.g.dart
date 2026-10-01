// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorization_progress.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How far along categorizing channels is, and whether it's doing some
/// again because the prompts changed.

@ProviderFor(CategorizationProgress)
final categorizationProgressProvider = CategorizationProgressProvider._();

/// How far along categorizing channels is, and whether it's doing some
/// again because the prompts changed.
final class CategorizationProgressProvider
    extends
        $NotifierProvider<
          CategorizationProgress,
          ({int done, bool redo, bool running, int total})
        > {
  /// How far along categorizing channels is, and whether it's doing some
  /// again because the prompts changed.
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
  Override overrideWithValue(
    ({int done, bool redo, bool running, int total}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({int done, bool redo, bool running, int total})>(
            value,
          ),
    );
  }
}

String _$categorizationProgressHash() =>
    r'b462c09f31e0a7a0e15103b5c894543f2596d818';

/// How far along categorizing channels is, and whether it's doing some
/// again because the prompts changed.

abstract class _$CategorizationProgress
    extends $Notifier<({int done, bool redo, bool running, int total})> {
  ({int done, bool redo, bool running, int total}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({int done, bool redo, bool running, int total}),
              ({int done, bool redo, bool running, int total})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({int done, bool redo, bool running, int total}),
                ({int done, bool redo, bool running, int total})
              >,
              ({int done, bool redo, bool running, int total}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
