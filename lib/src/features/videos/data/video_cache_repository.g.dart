// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_cache_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(videoCacheRepository)
final videoCacheRepositoryProvider = VideoCacheRepositoryProvider._();

final class VideoCacheRepositoryProvider
    extends
        $FunctionalProvider<
          VideoCacheRepository,
          VideoCacheRepository,
          VideoCacheRepository
        >
    with $Provider<VideoCacheRepository> {
  VideoCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoCacheRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<VideoCacheRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoCacheRepository create(Ref ref) {
    return videoCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoCacheRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoCacheRepository>(value),
    );
  }
}

String _$videoCacheRepositoryHash() =>
    r'1d7d7e448b6079ea29b9bc3a85a5e5c61b2229be';
