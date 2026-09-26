// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lost_sign_in.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'b0984f1fa8a993489055958eb0fce3b69270c68b';

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
