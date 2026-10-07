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
    extends $NotifierProvider<CategorizationProgress, RunProgress> {
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
  Override overrideWithValue(RunProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunProgress>(value),
    );
  }
}

String _$categorizationProgressHash() =>
    r'fd45857200cbc334f9e5114aa4ed760d09f54b64';

/// How far along categorizing channels is.

abstract class _$CategorizationProgress extends $Notifier<RunProgress> {
  RunProgress build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RunProgress, RunProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RunProgress, RunProgress>,
              RunProgress,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
