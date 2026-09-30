// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anthropic_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(anthropicRepository)
final anthropicRepositoryProvider = AnthropicRepositoryProvider._();

final class AnthropicRepositoryProvider
    extends
        $FunctionalProvider<
          AnthropicRepository,
          AnthropicRepository,
          AnthropicRepository
        >
    with $Provider<AnthropicRepository> {
  AnthropicRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'anthropicRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$anthropicRepositoryHash();

  @$internal
  @override
  $ProviderElement<AnthropicRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnthropicRepository create(Ref ref) {
    return anthropicRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnthropicRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnthropicRepository>(value),
    );
  }
}

String _$anthropicRepositoryHash() =>
    r'1452291897f46379b9ed058e6e1a57ed45b43e03';
