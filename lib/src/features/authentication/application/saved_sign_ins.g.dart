// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_sign_ins.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every saved sign-in, by the YouTube channel chosen when signing in, each
/// with a session ready to use. Looking sign-ins up and dropping ones that
/// stop working is `SignInService`'s.

@ProviderFor(SavedSignIns)
final savedSignInsProvider = SavedSignInsProvider._();

/// Every saved sign-in, by the YouTube channel chosen when signing in, each
/// with a session ready to use. Looking sign-ins up and dropping ones that
/// stop working is `SignInService`'s.
final class SavedSignInsProvider
    extends $AsyncNotifierProvider<SavedSignIns, Map<String, SignInProfile>> {
  /// Every saved sign-in, by the YouTube channel chosen when signing in, each
  /// with a session ready to use. Looking sign-ins up and dropping ones that
  /// stop working is `SignInService`'s.
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

String _$savedSignInsHash() => r'64f63c8184ab4cda726c60d0f3f65948e8d3673d';

/// Every saved sign-in, by the YouTube channel chosen when signing in, each
/// with a session ready to use. Looking sign-ins up and dropping ones that
/// stop working is `SignInService`'s.

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
