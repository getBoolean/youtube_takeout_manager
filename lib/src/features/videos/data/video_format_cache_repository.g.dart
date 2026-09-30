// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_format_cache_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(videoFormatCacheRepository)
final videoFormatCacheRepositoryProvider =
    VideoFormatCacheRepositoryProvider._();

final class VideoFormatCacheRepositoryProvider
    extends
        $FunctionalProvider<
          VideoFormatCacheRepository,
          VideoFormatCacheRepository,
          VideoFormatCacheRepository
        >
    with $Provider<VideoFormatCacheRepository> {
  VideoFormatCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoFormatCacheRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoFormatCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<VideoFormatCacheRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoFormatCacheRepository create(Ref ref) {
    return videoFormatCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoFormatCacheRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoFormatCacheRepository>(value),
    );
  }
}

String _$videoFormatCacheRepositoryHash() =>
    r'527d28cd4398ca042f5f4bba6babeaca752e1741';
