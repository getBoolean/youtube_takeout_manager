// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Signs channels in and out, looking each sign-in's channel up on YouTube,
/// and drops sign-ins that stop working. Nothing depends on it, so it can
/// use any provider.

@ProviderFor(SignInService)
final signInServiceProvider = SignInServiceProvider._();

/// Signs channels in and out, looking each sign-in's channel up on YouTube,
/// and drops sign-ins that stop working. Nothing depends on it, so it can
/// use any provider.
final class SignInServiceProvider
    extends $NotifierProvider<SignInService, void> {
  /// Signs channels in and out, looking each sign-in's channel up on YouTube,
  /// and drops sign-ins that stop working. Nothing depends on it, so it can
  /// use any provider.
  SignInServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInServiceHash();

  @$internal
  @override
  SignInService create() => SignInService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$signInServiceHash() => r'6423c7d9eec578d9178db1ce71f0cdcdac915126';

/// Signs channels in and out, looking each sign-in's channel up on YouTube,
/// and drops sign-ins that stop working. Nothing depends on it, so it can
/// use any provider.

abstract class _$SignInService extends $Notifier<void> {
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

/// Moves the sign-in saved before there was one per channel, once, at
/// start-up.

@ProviderFor(legacySignInMigration)
final legacySignInMigrationProvider = LegacySignInMigrationProvider._();

/// Moves the sign-in saved before there was one per channel, once, at
/// start-up.

final class LegacySignInMigrationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Moves the sign-in saved before there was one per channel, once, at
  /// start-up.
  LegacySignInMigrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'legacySignInMigrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$legacySignInMigrationHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return legacySignInMigration(ref);
  }
}

String _$legacySignInMigrationHash() =>
    r'c010256140bb281ac354ad9ea1eb6b9d66c605e8';
