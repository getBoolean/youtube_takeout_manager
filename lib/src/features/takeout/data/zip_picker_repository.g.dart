// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zip_picker_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(zipPickerRepository)
final zipPickerRepositoryProvider = ZipPickerRepositoryProvider._();

final class ZipPickerRepositoryProvider
    extends
        $FunctionalProvider<
          ZipPickerRepository,
          ZipPickerRepository,
          ZipPickerRepository
        >
    with $Provider<ZipPickerRepository> {
  ZipPickerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'zipPickerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$zipPickerRepositoryHash();

  @$internal
  @override
  $ProviderElement<ZipPickerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ZipPickerRepository create(Ref ref) {
    return zipPickerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ZipPickerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ZipPickerRepository>(value),
    );
  }
}

String _$zipPickerRepositoryHash() =>
    r'15873d25c70bdfbaad847d4d3c15d5f3d2ceaa76';
