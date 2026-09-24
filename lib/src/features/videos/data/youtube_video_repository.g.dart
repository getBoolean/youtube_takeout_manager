// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_video_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(youtubeVideoRepository)
final youtubeVideoRepositoryProvider = YoutubeVideoRepositoryProvider._();

final class YoutubeVideoRepositoryProvider
    extends
        $FunctionalProvider<
          YoutubeVideoRepository,
          YoutubeVideoRepository,
          YoutubeVideoRepository
        >
    with $Provider<YoutubeVideoRepository> {
  YoutubeVideoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'youtubeVideoRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$youtubeVideoRepositoryHash();

  @$internal
  @override
  $ProviderElement<YoutubeVideoRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  YoutubeVideoRepository create(Ref ref) {
    return youtubeVideoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(YoutubeVideoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<YoutubeVideoRepository>(value),
    );
  }
}

String _$youtubeVideoRepositoryHash() =>
    r'db86830b1cd7fd4abadcf90e3ebf99b14b2b50b0';
