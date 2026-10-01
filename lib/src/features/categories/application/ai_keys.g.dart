// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_keys.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The API keys the AI services categorize channels with: the build's, else
/// the ones entered in the app.

@ProviderFor(aiKeys)
final aiKeysProvider = AiKeysProvider._();

/// The API keys the AI services categorize channels with: the build's, else
/// the ones entered in the app.

final class AiKeysProvider
    extends $FunctionalProvider<AsyncValue<AiKeys>, AiKeys, FutureOr<AiKeys>>
    with $FutureModifier<AiKeys>, $FutureProvider<AiKeys> {
  /// The API keys the AI services categorize channels with: the build's, else
  /// the ones entered in the app.
  AiKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiKeysProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiKeysHash();

  @$internal
  @override
  $FutureProviderElement<AiKeys> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AiKeys> create(Ref ref) {
    return aiKeys(ref);
  }
}

String _$aiKeysHash() => r'801472c56e9ac411f09479792f0cb65801bffd9e';

/// Enters or clears the API keys of the AI services the build has none for,
/// checking each new key with its service first. Nothing depends on it, so
/// it can use any provider.

@ProviderFor(AiKeysSetup)
final aiKeysSetupProvider = AiKeysSetupProvider._();

/// Enters or clears the API keys of the AI services the build has none for,
/// checking each new key with its service first. Nothing depends on it, so
/// it can use any provider.
final class AiKeysSetupProvider extends $NotifierProvider<AiKeysSetup, void> {
  /// Enters or clears the API keys of the AI services the build has none for,
  /// checking each new key with its service first. Nothing depends on it, so
  /// it can use any provider.
  AiKeysSetupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiKeysSetupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiKeysSetupHash();

  @$internal
  @override
  AiKeysSetup create() => AiKeysSetup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$aiKeysSetupHash() => r'4493c8deb747911042d126754e8c7d1c36157918';

/// Enters or clears the API keys of the AI services the build has none for,
/// checking each new key with its service first. Nothing depends on it, so
/// it can use any provider.

abstract class _$AiKeysSetup extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
