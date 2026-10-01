// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_title_fetcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches details, like titles, of the viewed channel's videos and the
/// [ExtraVideoIds] not kept on this device yet, with whichever sign-in can
/// read them. Starts over when that sign-in, the viewed takeout or the extra
/// videos change, dropping the run under way.
///
/// An effect: nothing depends on it, so it can read any provider.

@ProviderFor(videoTitleFetcher)
final videoTitleFetcherProvider = VideoTitleFetcherProvider._();

/// Fetches details, like titles, of the viewed channel's videos and the
/// [ExtraVideoIds] not kept on this device yet, with whichever sign-in can
/// read them. Starts over when that sign-in, the viewed takeout or the extra
/// videos change, dropping the run under way.
///
/// An effect: nothing depends on it, so it can read any provider.

final class VideoTitleFetcherProvider
    extends $FunctionalProvider<AsyncValue<void>, void, Stream<void>>
    with $FutureModifier<void>, $StreamProvider<void> {
  /// Fetches details, like titles, of the viewed channel's videos and the
  /// [ExtraVideoIds] not kept on this device yet, with whichever sign-in can
  /// read them. Starts over when that sign-in, the viewed takeout or the extra
  /// videos change, dropping the run under way.
  ///
  /// An effect: nothing depends on it, so it can read any provider.
  VideoTitleFetcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoTitleFetcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoTitleFetcherHash();

  @$internal
  @override
  $StreamProviderElement<void> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<void> create(Ref ref) {
    return videoTitleFetcher(ref);
  }
}

String _$videoTitleFetcherHash() => r'f692818fc5362ce35045d8cfbceb31914ad8d573';
