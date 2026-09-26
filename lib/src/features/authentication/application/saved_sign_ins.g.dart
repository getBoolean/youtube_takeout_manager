// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_sign_ins.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether Google sign-in has a client configured. Overridable in tests.

@ProviderFor(oauthConfigured)
final oauthConfiguredProvider = OauthConfiguredProvider._();

/// Whether Google sign-in has a client configured. Overridable in tests.

final class OauthConfiguredProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether Google sign-in has a client configured. Overridable in tests.
  OauthConfiguredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oauthConfiguredProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oauthConfiguredHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return oauthConfigured(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$oauthConfiguredHash() => r'a71521b8cd5f0d0f0c3eb71d05e218d3995bd170';

/// The last sign-in that stopped working, for the UI to report.

@ProviderFor(LostSignInNotifier)
final lostSignInProvider = LostSignInNotifierProvider._();

/// The last sign-in that stopped working, for the UI to report.
final class LostSignInNotifierProvider
    extends $NotifierProvider<LostSignInNotifier, LostSignIn?> {
  /// The last sign-in that stopped working, for the UI to report.
  LostSignInNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lostSignInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lostSignInNotifierHash();

  @$internal
  @override
  LostSignInNotifier create() => LostSignInNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LostSignIn? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LostSignIn?>(value),
    );
  }
}

String _$lostSignInNotifierHash() =>
    r'7ee13c00f373e21daa57f60d0bc2e09d48af9a67';

/// The last sign-in that stopped working, for the UI to report.

abstract class _$LostSignInNotifier extends $Notifier<LostSignIn?> {
  LostSignIn? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LostSignIn?, LostSignIn?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LostSignIn?, LostSignIn?>,
              LostSignIn?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Every saved sign-in, by the YouTube channel chosen when signing in, each
/// with a session ready to use.

@ProviderFor(SavedSignIns)
final savedSignInsProvider = SavedSignInsProvider._();

/// Every saved sign-in, by the YouTube channel chosen when signing in, each
/// with a session ready to use.
final class SavedSignInsProvider
    extends $AsyncNotifierProvider<SavedSignIns, Map<String, SignInProfile>> {
  /// Every saved sign-in, by the YouTube channel chosen when signing in, each
  /// with a session ready to use.
  SavedSignInsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedSignInsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedSignInsHash();

  @$internal
  @override
  SavedSignIns create() => SavedSignIns();
}

String _$savedSignInsHash() => r'5ac0cac2b0e9c1c3e02a30d2f9e3a5e46246988f';

/// Every saved sign-in, by the YouTube channel chosen when signing in, each
/// with a session ready to use.

abstract class _$SavedSignIns
    extends $AsyncNotifier<Map<String, SignInProfile>> {
  FutureOr<Map<String, SignInProfile>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, SignInProfile>>,
              Map<String, SignInProfile>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, SignInProfile>>,
                Map<String, SignInProfile>
              >,
              AsyncValue<Map<String, SignInProfile>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
