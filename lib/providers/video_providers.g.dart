// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VideoMetadata)
final videoMetadataProvider = VideoMetadataProvider._();

final class VideoMetadataProvider
    extends $NotifierProvider<VideoMetadata, Map<String, Video>> {
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Video> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Video>>(value),
    );
  }
}

String _$videoMetadataHash() => r'c515e32c288c535f5c52e69cdada8e03a7b29668';

abstract class _$VideoMetadata extends $Notifier<Map<String, Video>> {
  Map<String, Video> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, Video>, Map<String, Video>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, Video>, Map<String, Video>>,
              Map<String, Video>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
