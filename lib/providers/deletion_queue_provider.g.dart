// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_queue_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$deletionQueueHash() => r'4691d6d2b4475284c07629ecfaee0be0c1ef148b';

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
