// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_processing.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Deletes queued items through the YouTube API, one at a time, and says
/// whether it's doing so. A service: nothing depends on it, so it can read
/// any provider.

@ProviderFor(DeletionProcessing)
final deletionProcessingProvider = DeletionProcessingProvider._();

/// Deletes queued items through the YouTube API, one at a time, and says
/// whether it's doing so. A service: nothing depends on it, so it can read
/// any provider.
final class DeletionProcessingProvider
    extends $NotifierProvider<DeletionProcessing, DeletionProcessingState> {
  /// Deletes queued items through the YouTube API, one at a time, and says
  /// whether it's doing so. A service: nothing depends on it, so it can read
  /// any provider.
  DeletionProcessingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletionProcessingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletionProcessingHash();

  @$internal
  @override
  DeletionProcessing create() => DeletionProcessing();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeletionProcessingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeletionProcessingState>(value),
    );
  }
}

String _$deletionProcessingHash() =>
    r'f2f5b41e928d8d6f9b4c82b7dae8bd6c6c9d4f97';

/// Deletes queued items through the YouTube API, one at a time, and says
/// whether it's doing so. A service: nothing depends on it, so it can read
/// any provider.

abstract class _$DeletionProcessing extends $Notifier<DeletionProcessingState> {
  DeletionProcessingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<DeletionProcessingState, DeletionProcessingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeletionProcessingState, DeletionProcessingState>,
              DeletionProcessingState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
