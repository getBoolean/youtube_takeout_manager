// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_pause_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(aiPauseRepository)
final aiPauseRepositoryProvider = AiPauseRepositoryProvider._();

final class AiPauseRepositoryProvider
    extends
        $FunctionalProvider<
          AiPauseRepository,
          AiPauseRepository,
          AiPauseRepository
        >
    with $Provider<AiPauseRepository> {
  AiPauseRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiPauseRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiPauseRepositoryHash();

  @$internal
  @override
  $ProviderElement<AiPauseRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiPauseRepository create(Ref ref) {
    return aiPauseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiPauseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiPauseRepository>(value),
    );
  }
}

String _$aiPauseRepositoryHash() => r'30503ddd195d4910ca3efd05c96a76d9b5d5f9bc';
