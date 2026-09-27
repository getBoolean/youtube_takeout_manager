// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_file_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exportFileRepository)
final exportFileRepositoryProvider = ExportFileRepositoryProvider._();

final class ExportFileRepositoryProvider
    extends
        $FunctionalProvider<
          ExportFileRepository,
          ExportFileRepository,
          ExportFileRepository
        >
    with $Provider<ExportFileRepository> {
  ExportFileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportFileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportFileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ExportFileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExportFileRepository create(Ref ref) {
    return exportFileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportFileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportFileRepository>(value),
    );
  }
}

String _$exportFileRepositoryHash() =>
    r'f88211612faacb025cde599328b1a93d50c30663';
