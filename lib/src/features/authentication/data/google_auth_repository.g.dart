// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(googleAuthRepository)
final googleAuthRepositoryProvider = GoogleAuthRepositoryProvider._();

final class GoogleAuthRepositoryProvider
    extends
        $FunctionalProvider<
          GoogleAuthRepository,
          GoogleAuthRepository,
          GoogleAuthRepository
        >
    with $Provider<GoogleAuthRepository> {
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
    r'e2db603cfbb33e4db29f065791d29254515ef25c';
