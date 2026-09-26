// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_title_fetcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches details, like titles, of the viewed channel's videos not kept on
/// this device yet, with whichever sign-in can read them. Starts over when
/// that sign-in or the viewed takeout changes, dropping the run under way.
///
/// An effect: nothing depends on it, so it can read any provider.

@ProviderFor(videoTitleFetcher)
final videoTitleFetcherProvider = VideoTitleFetcherProvider._();

/// Fetches details, like titles, of the viewed channel's videos not kept on
/// this device yet, with whichever sign-in can read them. Starts over when
/// that sign-in or the viewed takeout changes, dropping the run under way.
///
/// An effect: nothing depends on it, so it can read any provider.

final class VideoTitleFetcherProvider
    extends $FunctionalProvider<AsyncValue<void>, void, Stream<void>>
    with $FutureModifier<void>, $StreamProvider<void> {
  /// Fetches details, like titles, of the viewed channel's videos not kept on
  /// this device yet, with whichever sign-in can read them. Starts over when
  /// that sign-in or the viewed takeout changes, dropping the run under way.
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

String _$videoTitleFetcherHash() => r'90b263c69b7da1d023f5bff54605306cb1d4f562';
