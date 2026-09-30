// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oauth_client_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(oauthClientRepository)
final oauthClientRepositoryProvider = OauthClientRepositoryProvider._();

final class OauthClientRepositoryProvider
    extends
        $FunctionalProvider<
          OAuthClientRepository,
          OAuthClientRepository,
          OAuthClientRepository
        >
    with $Provider<OAuthClientRepository> {
  OauthClientRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oauthClientRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oauthClientRepositoryHash();

  @$internal
  @override
  $ProviderElement<OAuthClientRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OAuthClientRepository create(Ref ref) {
    return oauthClientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OAuthClientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OAuthClientRepository>(value),
    );
  }
}

String _$oauthClientRepositoryHash() =>
    r'f33768570989b79a9ae57dc58a6c3cc6561e8643';

/// The Google Cloud client that signs in, or null until there is one.

@ProviderFor(oauthClient)
final oauthClientProvider = OauthClientProvider._();

/// The Google Cloud client that signs in, or null until there is one.

final class OauthClientProvider
    extends
        $FunctionalProvider<
          AsyncValue<OAuthClient?>,
          OAuthClient?,
          FutureOr<OAuthClient?>
        >
    with $FutureModifier<OAuthClient?>, $FutureProvider<OAuthClient?> {
  /// The Google Cloud client that signs in, or null until there is one.
  OauthClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oauthClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oauthClientHash();

  @$internal
  @override
  $FutureProviderElement<OAuthClient?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OAuthClient?> create(Ref ref) {
    return oauthClient(ref);
  }
}

String _$oauthClientHash() => r'f47ba6af759117ccc14b693166ee559172c4c19b';
