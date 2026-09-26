// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_notices.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Signs channels in from the account dialog, keeping why one didn't end up
/// signed in, by channel ID, to show on its row until dismissed.

@ProviderFor(SignInNotices)
final signInNoticesProvider = SignInNoticesProvider._();

/// Signs channels in from the account dialog, keeping why one didn't end up
/// signed in, by channel ID, to show on its row until dismissed.
final class SignInNoticesProvider
    extends $NotifierProvider<SignInNotices, Map<String, SignInNotice>> {
  /// Signs channels in from the account dialog, keeping why one didn't end up
  /// signed in, by channel ID, to show on its row until dismissed.
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

String _$signInNoticesHash() => r'a92217636f8a63083a3bdd0235fcf18672febe5d';

/// Signs channels in from the account dialog, keeping why one didn't end up
/// signed in, by channel ID, to show on its row until dismissed.

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
