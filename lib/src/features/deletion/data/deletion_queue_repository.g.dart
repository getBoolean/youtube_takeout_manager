// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_queue_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deletionQueueRepository)
final deletionQueueRepositoryProvider = DeletionQueueRepositoryProvider._();

final class DeletionQueueRepositoryProvider
    extends
        $FunctionalProvider<
          DeletionQueueRepository,
          DeletionQueueRepository,
          DeletionQueueRepository
        >
    with $Provider<DeletionQueueRepository> {
  DeletionQueueRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletionQueueRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletionQueueRepositoryHash();

  @$internal
  @override
  $ProviderElement<DeletionQueueRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeletionQueueRepository create(Ref ref) {
    return deletionQueueRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeletionQueueRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeletionQueueRepository>(value),
    );
  }
}

String _$deletionQueueRepositoryHash() =>
    r'04e54bbb0c24756df3625981c21dca6e7e2a3aeb';
