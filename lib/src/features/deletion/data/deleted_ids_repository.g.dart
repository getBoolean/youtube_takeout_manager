// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_ids_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deletedIdsRepository)
final deletedIdsRepositoryProvider = DeletedIdsRepositoryProvider._();

final class DeletedIdsRepositoryProvider
    extends
        $FunctionalProvider<
          DeletedIdsRepository,
          DeletedIdsRepository,
          DeletedIdsRepository
        >
    with $Provider<DeletedIdsRepository> {
  DeletedIdsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletedIdsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletedIdsRepositoryHash();

  @$internal
  @override
  $ProviderElement<DeletedIdsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeletedIdsRepository create(Ref ref) {
    return deletedIdsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeletedIdsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeletedIdsRepository>(value),
    );
  }
}

String _$deletedIdsRepositoryHash() =>
    r'bd96d7e96bbb7ab821db5390dca3823d6326140c';
