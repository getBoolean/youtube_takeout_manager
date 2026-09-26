// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The viewed channel's sign-in, or null when it has none: a channel counts
/// as signed in only with the sign-in chosen for it.

@ProviderFor(AuthNotifier)
final authProvider = AuthNotifierProvider._();

/// The viewed channel's sign-in, or null when it has none: a channel counts
/// as signed in only with the sign-in chosen for it.
final class AuthNotifierProvider
    extends $NotifierProvider<AuthNotifier, AuthState?> {
  /// The viewed channel's sign-in, or null when it has none: a channel counts
  /// as signed in only with the sign-in chosen for it.
  AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState?>(value),
    );
  }
}

String _$authNotifierHash() => r'16320a3afa1bf051ab0310006116f203ede57cdb';

/// The viewed channel's sign-in, or null when it has none: a channel counts
/// as signed in only with the sign-in chosen for it.

abstract class _$AuthNotifier extends $Notifier<AuthState?> {
  AuthState? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthState?, AuthState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState?, AuthState?>,
              AuthState?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = IsAuthenticatedProvider._();

final class IsAuthenticatedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsAuthenticatedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAuthenticatedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAuthenticatedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAuthenticated(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAuthenticatedHash() => r'c14197894b47544a94cb7a1d409a70845391c79c';
