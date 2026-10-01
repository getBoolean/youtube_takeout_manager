// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_capabilities_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(modelCapabilitiesRepository)
final modelCapabilitiesRepositoryProvider =
    ModelCapabilitiesRepositoryProvider._();

final class ModelCapabilitiesRepositoryProvider
    extends
        $FunctionalProvider<
          ModelCapabilitiesRepository,
          ModelCapabilitiesRepository,
          ModelCapabilitiesRepository
        >
    with $Provider<ModelCapabilitiesRepository> {
  ModelCapabilitiesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelCapabilitiesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelCapabilitiesRepositoryHash();

  @$internal
  @override
  $ProviderElement<ModelCapabilitiesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ModelCapabilitiesRepository create(Ref ref) {
    return modelCapabilitiesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelCapabilitiesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelCapabilitiesRepository>(value),
    );
  }
}

String _$modelCapabilitiesRepositoryHash() =>
    r'85f731d15013ff0bbfd47995482ca0016b9a2ef5';
