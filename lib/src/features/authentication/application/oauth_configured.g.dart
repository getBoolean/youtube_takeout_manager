// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oauth_configured.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether Google sign-in has a client, and with it everything that uses
/// the YouTube API. Overridable in tests.

@ProviderFor(oauthConfigured)
final oauthConfiguredProvider = OauthConfiguredProvider._();

/// Whether Google sign-in has a client, and with it everything that uses
/// the YouTube API. Overridable in tests.

final class OauthConfiguredProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether Google sign-in has a client, and with it everything that uses
  /// the YouTube API. Overridable in tests.
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

String _$oauthConfiguredHash() => r'77bd40a471c0ca1e1095d7463688b75427795acb';
