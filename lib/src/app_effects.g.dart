// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_effects.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Starts the app's background work, each piece its own provider that
/// listens for what it reacts to. The app listens to this for as long as
/// it runs.
///
/// Effects are services: nothing watches them, so they can read any
/// provider without closing a loop. They change other providers only after
/// an await, never synchronously while starting.

@ProviderFor(appEffects)
final appEffectsProvider = AppEffectsProvider._();

/// Starts the app's background work, each piece its own provider that
/// listens for what it reacts to. The app listens to this for as long as
/// it runs.
///
/// Effects are services: nothing watches them, so they can read any
/// provider without closing a loop. They change other providers only after
/// an await, never synchronously while starting.

final class AppEffectsProvider extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Starts the app's background work, each piece its own provider that
  /// listens for what it reacts to. The app listens to this for as long as
  /// it runs.
  ///
  /// Effects are services: nothing watches them, so they can read any
  /// provider without closing a loop. They change other providers only after
  /// an await, never synchronously while starting.
  AppEffectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appEffectsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appEffectsHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return appEffects(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$appEffectsHash() => r'0066fb2dfdb0ed483b74dc6c129bff2d8fa68d85';
