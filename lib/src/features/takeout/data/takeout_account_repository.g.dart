// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeout_account_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(takeoutAccountRepository)
final takeoutAccountRepositoryProvider = TakeoutAccountRepositoryProvider._();

final class TakeoutAccountRepositoryProvider
    extends
        $FunctionalProvider<
          TakeoutAccountRepository,
          TakeoutAccountRepository,
          TakeoutAccountRepository
        >
    with $Provider<TakeoutAccountRepository> {
  TakeoutAccountRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'takeoutAccountRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$takeoutAccountRepositoryHash();

  @$internal
  @override
  $ProviderElement<TakeoutAccountRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TakeoutAccountRepository create(Ref ref) {
    return takeoutAccountRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TakeoutAccountRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TakeoutAccountRepository>(value),
    );
  }
}

String _$takeoutAccountRepositoryHash() =>
    r'5b9f425397a4833946b837ec8bec57f27c3ae5fc';
