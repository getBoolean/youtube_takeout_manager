// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeout_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(takeoutRepository)
final takeoutRepositoryProvider = TakeoutRepositoryProvider._();

final class TakeoutRepositoryProvider
    extends
        $FunctionalProvider<
          TakeoutRepository,
          TakeoutRepository,
          TakeoutRepository
        >
    with $Provider<TakeoutRepository> {
  TakeoutRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'takeoutRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$takeoutRepositoryHash();

  @$internal
  @override
  $ProviderElement<TakeoutRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TakeoutRepository create(Ref ref) {
    return takeoutRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TakeoutRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TakeoutRepository>(value),
    );
  }
}

String _$takeoutRepositoryHash() => r'e5e74f098edfd7225b1ab80dca93b68ab3fd9707';
