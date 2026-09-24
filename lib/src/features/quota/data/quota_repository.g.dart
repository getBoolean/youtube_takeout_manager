// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quota_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(quotaRepository)
final quotaRepositoryProvider = QuotaRepositoryProvider._();

final class QuotaRepositoryProvider
    extends
        $FunctionalProvider<QuotaRepository, QuotaRepository, QuotaRepository>
    with $Provider<QuotaRepository> {
  QuotaRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quotaRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quotaRepositoryHash();

  @$internal
  @override
  $ProviderElement<QuotaRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QuotaRepository create(Ref ref) {
    return quotaRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuotaRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuotaRepository>(value),
    );
  }
}

String _$quotaRepositoryHash() => r'd20b974057f6674cddcccd1fdf266957e6116a66';
