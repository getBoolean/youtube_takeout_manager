// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_generator_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(scriptGeneratorService)
final scriptGeneratorServiceProvider = ScriptGeneratorServiceProvider._();

final class ScriptGeneratorServiceProvider
    extends
        $FunctionalProvider<
          ScriptGeneratorService,
          ScriptGeneratorService,
          ScriptGeneratorService
        >
    with $Provider<ScriptGeneratorService> {
  ScriptGeneratorServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scriptGeneratorServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scriptGeneratorServiceHash();

  @$internal
  @override
  $ProviderElement<ScriptGeneratorService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScriptGeneratorService create(Ref ref) {
    return scriptGeneratorService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScriptGeneratorService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScriptGeneratorService>(value),
    );
  }
}

String _$scriptGeneratorServiceHash() =>
    r'c88f4ddc089454fe6e6129ecc0e8f555fbae673e';
