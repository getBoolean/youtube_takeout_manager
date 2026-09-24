// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kv_storage_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(kvStorageService)
final kvStorageServiceProvider = KvStorageServiceProvider._();

final class KvStorageServiceProvider
    extends
        $FunctionalProvider<
          KvStorageService,
          KvStorageService,
          KvStorageService
        >
    with $Provider<KvStorageService> {
  KvStorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kvStorageServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kvStorageServiceHash();

  @$internal
  @override
  $ProviderElement<KvStorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KvStorageService create(Ref ref) {
    return kvStorageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KvStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KvStorageService>(value),
    );
  }
}

String _$kvStorageServiceHash() => r'dcfe67b41c2ac77c86093d0994391c800c19184b';
