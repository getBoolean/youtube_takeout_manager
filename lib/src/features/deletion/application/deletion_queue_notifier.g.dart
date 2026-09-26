// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_queue_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The items queued to be deleted, kept on this device. Deleting them
/// through the YouTube API is `DeletionProcessing`'s.

@ProviderFor(DeletionQueue)
final deletionQueueProvider = DeletionQueueProvider._();

/// The items queued to be deleted, kept on this device. Deleting them
/// through the YouTube API is `DeletionProcessing`'s.
final class DeletionQueueProvider
    extends $AsyncNotifierProvider<DeletionQueue, List<DeletionQueueItem>> {
  /// The items queued to be deleted, kept on this device. Deleting them
  /// through the YouTube API is `DeletionProcessing`'s.
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

String _$deletionQueueHash() => r'bb7e69da3f18682d51e7dcff569726a4ca114f65';

/// The items queued to be deleted, kept on this device. Deleting them
/// through the YouTube API is `DeletionProcessing`'s.

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
