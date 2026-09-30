// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watched_video_format_fetcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the length and shape of every watched video not known yet, the
/// newest first, to tell Shorts apart: YouTube has no field saying which is
/// which. Waits for the history screen to be opened, and needs a sign-in.
/// Starts over when the sign-in or the history changes, dropping the run
/// under way.
///
/// An effect: nothing depends on it, so it can read any provider.

@ProviderFor(watchedVideoFormatFetcher)
final watchedVideoFormatFetcherProvider = WatchedVideoFormatFetcherProvider._();

/// Fetches the length and shape of every watched video not known yet, the
/// newest first, to tell Shorts apart: YouTube has no field saying which is
/// which. Waits for the history screen to be opened, and needs a sign-in.
/// Starts over when the sign-in or the history changes, dropping the run
/// under way.
///
/// An effect: nothing depends on it, so it can read any provider.

final class WatchedVideoFormatFetcherProvider
    extends $FunctionalProvider<AsyncValue<void>, void, Stream<void>>
    with $FutureModifier<void>, $StreamProvider<void> {
  /// Fetches the length and shape of every watched video not known yet, the
  /// newest first, to tell Shorts apart: YouTube has no field saying which is
  /// which. Waits for the history screen to be opened, and needs a sign-in.
  /// Starts over when the sign-in or the history changes, dropping the run
  /// under way.
  ///
  /// An effect: nothing depends on it, so it can read any provider.
  WatchedVideoFormatFetcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchedVideoFormatFetcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchedVideoFormatFetcherHash();

  @$internal
  @override
  $StreamProviderElement<void> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<void> create(Ref ref) {
    return watchedVideoFormatFetcher(ref);
  }
}

String _$watchedVideoFormatFetcherHash() =>
    r'925b54278ddb944c60bf053b442c879ce5ddac7d';
