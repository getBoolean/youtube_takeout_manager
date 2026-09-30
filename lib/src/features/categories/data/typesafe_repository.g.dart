// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typesafe_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(typeSafeRepository)
final typeSafeRepositoryProvider = TypeSafeRepositoryProvider._();

final class TypeSafeRepositoryProvider
    extends
        $FunctionalProvider<
          TypeSafeRepository,
          TypeSafeRepository,
          TypeSafeRepository
        >
    with $Provider<TypeSafeRepository> {
  TypeSafeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'typeSafeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$typeSafeRepositoryHash();

  @$internal
  @override
  $ProviderElement<TypeSafeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TypeSafeRepository create(Ref ref) {
    return typeSafeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TypeSafeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TypeSafeRepository>(value),
    );
  }
}

String _$typeSafeRepositoryHash() =>
    r'f2ed37aa1be3e58b6636d55bbf66c0e20da32249';
