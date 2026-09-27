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

/// Videos to fetch details of besides the viewed takeout's, e.g. those of
/// new items in a takeout being reviewed. Fetching them is
/// `videoTitleFetcher`'s.

@ProviderFor(ExtraVideoIds)
final extraVideoIdsProvider = ExtraVideoIdsProvider._();

/// Videos to fetch details of besides the viewed takeout's, e.g. those of
/// new items in a takeout being reviewed. Fetching them is
/// `videoTitleFetcher`'s.
final class ExtraVideoIdsProvider
    extends $NotifierProvider<ExtraVideoIds, Set<String>> {
  /// Videos to fetch details of besides the viewed takeout's, e.g. those of
  /// new items in a takeout being reviewed. Fetching them is
  /// `videoTitleFetcher`'s.
  ExtraVideoIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'extraVideoIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$extraVideoIdsHash();

  @$internal
  @override
  ExtraVideoIds create() => ExtraVideoIds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$extraVideoIdsHash() => r'95ab278d9b0442b9da88598a95828ff48143b341';

/// Videos to fetch details of besides the viewed takeout's, e.g. those of
/// new items in a takeout being reviewed. Fetching them is
/// `videoTitleFetcher`'s.

abstract class _$ExtraVideoIds extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Details of the videos commented or chatted on, by video ID, kept on this
/// device. Fetching more is `videoTitleFetcher`'s.

@ProviderFor(VideoMetadata)
final videoMetadataProvider = VideoMetadataProvider._();

/// Details of the videos commented or chatted on, by video ID, kept on this
/// device. Fetching more is `videoTitleFetcher`'s.
final class VideoMetadataProvider
    extends $StreamNotifierProvider<VideoMetadata, Map<String, Video>> {
  /// Details of the videos commented or chatted on, by video ID, kept on this
  /// device. Fetching more is `videoTitleFetcher`'s.
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

String _$videoMetadataHash() => r'5c76d066d6328a55a45164efc4231df1b08d8640';

/// Details of the videos commented or chatted on, by video ID, kept on this
/// device. Fetching more is `videoTitleFetcher`'s.

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
