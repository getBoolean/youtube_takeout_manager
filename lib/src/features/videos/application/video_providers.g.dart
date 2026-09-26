// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VideoFetchProgress)
final videoFetchProgressProvider = VideoFetchProgressProvider._();

final class VideoFetchProgressProvider
    extends
        $NotifierProvider<
          VideoFetchProgress,
          ({int fetched, bool isFetching, int total})
        > {
  VideoFetchProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoFetchProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoFetchProgressHash();

  @$internal
  @override
  VideoFetchProgress create() => VideoFetchProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({int fetched, bool isFetching, int total}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({int fetched, bool isFetching, int total})>(
            value,
          ),
    );
  }
}

String _$videoFetchProgressHash() =>
    r'71c56d8de1e63d9c7f5588b92ecaa9eb0acfa425';

abstract class _$VideoFetchProgress
    extends $Notifier<({int fetched, bool isFetching, int total})> {
  ({int fetched, bool isFetching, int total}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({int fetched, bool isFetching, int total}),
              ({int fetched, bool isFetching, int total})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({int fetched, bool isFetching, int total}),
                ({int fetched, bool isFetching, int total})
              >,
              ({int fetched, bool isFetching, int total}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(VideoMetadata)
final videoMetadataProvider = VideoMetadataProvider._();

final class VideoMetadataProvider
    extends $StreamNotifierProvider<VideoMetadata, Map<String, Video>> {
  VideoMetadataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoMetadataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoMetadataHash();

  @$internal
  @override
  VideoMetadata create() => VideoMetadata();
}

String _$videoMetadataHash() => r'bbbe9931882e46846f404d34680c93c254e61375';

abstract class _$VideoMetadata extends $StreamNotifier<Map<String, Video>> {
  Stream<Map<String, Video>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, Video>>, Map<String, Video>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, Video>>, Map<String, Video>>,
              AsyncValue<Map<String, Video>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
