// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_keys_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiKeysRepository)
final aiKeysRepositoryProvider = AiKeysRepositoryProvider._();

final class AiKeysRepositoryProvider
    extends
        $FunctionalProvider<
          AiKeysRepository,
          AiKeysRepository,
          AiKeysRepository
        >
    with $Provider<AiKeysRepository> {
  AiKeysRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiKeysRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiKeysRepositoryHash();

  @$internal
  @override
  $ProviderElement<AiKeysRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AiKeysRepository create(Ref ref) {
    return aiKeysRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiKeysRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiKeysRepository>(value),
    );
  }
}

String _$aiKeysRepositoryHash() => r'1d12e7e2c61bccb087f4c2f419ccc882c0414e40';
