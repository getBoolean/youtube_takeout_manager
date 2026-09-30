// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sign-ins through the Google Cloud client, made anew when it changes.
/// Every channel is signed out before it does, so no session is left
/// behind.

@ProviderFor(googleAuthRepository)
final googleAuthRepositoryProvider = GoogleAuthRepositoryProvider._();

/// Sign-ins through the Google Cloud client, made anew when it changes.
/// Every channel is signed out before it does, so no session is left
/// behind.

final class GoogleAuthRepositoryProvider
    extends
        $FunctionalProvider<
          GoogleAuthRepository,
          GoogleAuthRepository,
          GoogleAuthRepository
        >
    with $Provider<GoogleAuthRepository> {
  /// Sign-ins through the Google Cloud client, made anew when it changes.
  /// Every channel is signed out before it does, so no session is left
  /// behind.
  GoogleAuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleAuthRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleAuthRepositoryHash();

  @$internal
  @override
  $ProviderElement<GoogleAuthRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GoogleAuthRepository create(Ref ref) {
    return googleAuthRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleAuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleAuthRepository>(value),
    );
  }
}

String _$googleAuthRepositoryHash() =>
    r'920ef32f4d51741422c4844a09e3eccb5b2922f3';
