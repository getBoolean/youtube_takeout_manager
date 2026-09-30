// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_format_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The watched videos' lengths and shapes known on this device, by video
/// ID. Fetching more is `watchedVideoFormatFetcher`'s.

@ProviderFor(VideoFormats)
final videoFormatsProvider = VideoFormatsProvider._();

/// The watched videos' lengths and shapes known on this device, by video
/// ID. Fetching more is `watchedVideoFormatFetcher`'s.
final class VideoFormatsProvider
    extends $AsyncNotifierProvider<VideoFormats, Map<String, VideoFormat>> {
  /// The watched videos' lengths and shapes known on this device, by video
  /// ID. Fetching more is `watchedVideoFormatFetcher`'s.
  VideoFormatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoFormatsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoFormatsHash();

  @$internal
  @override
  VideoFormats create() => VideoFormats();
}

String _$videoFormatsHash() => r'27a3bad3b1dd8ab2d6316a3dc51fb8794faefd87';

/// The watched videos' lengths and shapes known on this device, by video
/// ID. Fetching more is `watchedVideoFormatFetcher`'s.

abstract class _$VideoFormats extends $AsyncNotifier<Map<String, VideoFormat>> {
  FutureOr<Map<String, VideoFormat>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, VideoFormat>>,
              Map<String, VideoFormat>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, VideoFormat>>,
                Map<String, VideoFormat>
              >,
              AsyncValue<Map<String, VideoFormat>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// How far along fetching the watched videos' formats is.

@ProviderFor(VideoFormatProgress)
final videoFormatProgressProvider = VideoFormatProgressProvider._();

/// How far along fetching the watched videos' formats is.
final class VideoFormatProgressProvider
    extends
        $NotifierProvider<
          VideoFormatProgress,
          ({int done, bool running, int total})
        > {
  /// How far along fetching the watched videos' formats is.
  VideoFormatProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoFormatProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoFormatProgressHash();

  @$internal
  @override
  VideoFormatProgress create() => VideoFormatProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int done, bool running, int total}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({int done, bool running, int total})>(value),
    );
  }
}

String _$videoFormatProgressHash() =>
    r'a1d817233e0e703025c52ebabb0c8cc53e597fef';

/// How far along fetching the watched videos' formats is.

abstract class _$VideoFormatProgress
    extends $Notifier<({int done, bool running, int total})> {
  ({int done, bool running, int total}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({int done, bool running, int total}),
              ({int done, bool running, int total})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({int done, bool running, int total}),
                ({int done, bool running, int total})
              >,
              ({int done, bool running, int total}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
