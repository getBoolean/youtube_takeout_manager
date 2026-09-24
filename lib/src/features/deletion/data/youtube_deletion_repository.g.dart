// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_deletion_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(youtubeDeletionRepository)
final youtubeDeletionRepositoryProvider = YoutubeDeletionRepositoryProvider._();

final class YoutubeDeletionRepositoryProvider
    extends
        $FunctionalProvider<
          YoutubeDeletionRepository,
          YoutubeDeletionRepository,
          YoutubeDeletionRepository
        >
    with $Provider<YoutubeDeletionRepository> {
  YoutubeDeletionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'youtubeDeletionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$youtubeDeletionRepositoryHash();

  @$internal
  @override
  $ProviderElement<YoutubeDeletionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  YoutubeDeletionRepository create(Ref ref) {
    return youtubeDeletionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(YoutubeDeletionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<YoutubeDeletionRepository>(value),
    );
  }
}

String _$youtubeDeletionRepositoryHash() =>
    r'64cbf11469397097b566add415cecb21777b723c';
