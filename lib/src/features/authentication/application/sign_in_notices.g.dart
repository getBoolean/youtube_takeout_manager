// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_notices.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Why channels signed in from the Takeouts dialog didn't end up signed in,
/// by channel ID, until dismissed. Shown through [SignInNotices].

@ProviderFor(SignInAttemptNotices)
final signInAttemptNoticesProvider = SignInAttemptNoticesProvider._();

/// Why channels signed in from the Takeouts dialog didn't end up signed in,
/// by channel ID, until dismissed. Shown through [SignInNotices].
final class SignInAttemptNoticesProvider
    extends $NotifierProvider<SignInAttemptNotices, Map<String, SignInNotice>> {
  /// Why channels signed in from the Takeouts dialog didn't end up signed in,
  /// by channel ID, until dismissed. Shown through [SignInNotices].
  SignInAttemptNoticesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInAttemptNoticesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInAttemptNoticesHash();

  @$internal
  @override
  SignInAttemptNotices create() => SignInAttemptNotices();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, SignInNotice> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, SignInNotice>>(value),
    );
  }
}

String _$signInAttemptNoticesHash() =>
    r'dd3ed1599fa8677bc56570c6fa8c7f8bd4a6a56b';

/// Why channels signed in from the Takeouts dialog didn't end up signed in,
/// by channel ID, until dismissed. Shown through [SignInNotices].

abstract class _$SignInAttemptNotices
    extends $Notifier<Map<String, SignInNotice>> {
  Map<String, SignInNotice> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<Map<String, SignInNotice>, Map<String, SignInNotice>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, SignInNotice>, Map<String, SignInNotice>>,
              Map<String, SignInNotice>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Each channel's notice for its row in the Takeouts dialog, by channel ID:
/// why signing it in from there didn't work, or that its saved sign-in
/// stopped working. Also signs channels in from there.

@ProviderFor(SignInNotices)
final signInNoticesProvider = SignInNoticesProvider._();

/// Each channel's notice for its row in the Takeouts dialog, by channel ID:
/// why signing it in from there didn't work, or that its saved sign-in
/// stopped working. Also signs channels in from there.
final class SignInNoticesProvider
    extends $NotifierProvider<SignInNotices, Map<String, SignInNotice>> {
  /// Each channel's notice for its row in the Takeouts dialog, by channel ID:
  /// why signing it in from there didn't work, or that its saved sign-in
  /// stopped working. Also signs channels in from there.
  SignInNoticesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInNoticesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInNoticesHash();

  @$internal
  @override
  SignInNotices create() => SignInNotices();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, SignInNotice> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, SignInNotice>>(value),
    );
  }
}

String _$signInNoticesHash() => r'3fc9718fb8c89534e37bc17503ee94674e9e0a0a';

/// Each channel's notice for its row in the Takeouts dialog, by channel ID:
/// why signing it in from there didn't work, or that its saved sign-in
/// stopped working. Also signs channels in from there.

abstract class _$SignInNotices extends $Notifier<Map<String, SignInNotice>> {
  Map<String, SignInNotice> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<Map<String, SignInNotice>, Map<String, SignInNotice>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, SignInNotice>, Map<String, SignInNotice>>,
              Map<String, SignInNotice>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
