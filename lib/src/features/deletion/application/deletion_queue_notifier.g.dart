// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_queue_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the deletion queue is being processed via the YouTube API. Set by
/// [DeletionQueue].

@ProviderFor(DeletionProcessing)
final deletionProcessingProvider = DeletionProcessingProvider._();

/// Whether the deletion queue is being processed via the YouTube API. Set by
/// [DeletionQueue].
final class DeletionProcessingProvider
    extends $NotifierProvider<DeletionProcessing, DeletionProcessingState> {
  /// Whether the deletion queue is being processed via the YouTube API. Set by
  /// [DeletionQueue].
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
    r'c92f6de154a75a4dccbbcbebcce2a895e3bae447';

/// Whether the deletion queue is being processed via the YouTube API. Set by
/// [DeletionQueue].

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

@ProviderFor(DeletionQueue)
final deletionQueueProvider = DeletionQueueProvider._();

final class DeletionQueueProvider
    extends $AsyncNotifierProvider<DeletionQueue, List<DeletionQueueItem>> {
  DeletionQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletionQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletionQueueHash();

  @$internal
  @override
  DeletionQueue create() => DeletionQueue();
}

String _$deletionQueueHash() => r'4a59145ec00d719e8d369b5bdfc15e7a0a8ae387';

abstract class _$DeletionQueue extends $AsyncNotifier<List<DeletionQueueItem>> {
  FutureOr<List<DeletionQueueItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<DeletionQueueItem>>,
              List<DeletionQueueItem>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<DeletionQueueItem>>,
                List<DeletionQueueItem>
              >,
              AsyncValue<List<DeletionQueueItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
