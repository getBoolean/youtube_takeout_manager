// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_details_fetcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches details, such as descriptions, of videos asked for by ID, like
/// the watched videos AI is told about: signed in, while the quota lasts,
/// and only for those neither kept on this device nor known to be gone.
/// Each request is counted against the quota. Signed out, nothing is
/// fetched; what's kept is all there is.
///
/// A service: nothing depends on it, so it can read any provider.

@ProviderFor(VideoDetailsFetcher)
final videoDetailsFetcherProvider = VideoDetailsFetcherProvider._();

/// Fetches details, such as descriptions, of videos asked for by ID, like
/// the watched videos AI is told about: signed in, while the quota lasts,
/// and only for those neither kept on this device nor known to be gone.
/// Each request is counted against the quota. Signed out, nothing is
/// fetched; what's kept is all there is.
///
/// A service: nothing depends on it, so it can read any provider.
final class VideoDetailsFetcherProvider
    extends $NotifierProvider<VideoDetailsFetcher, void> {
  /// Fetches details, such as descriptions, of videos asked for by ID, like
  /// the watched videos AI is told about: signed in, while the quota lasts,
  /// and only for those neither kept on this device nor known to be gone.
  /// Each request is counted against the quota. Signed out, nothing is
  /// fetched; what's kept is all there is.
  ///
  /// A service: nothing depends on it, so it can read any provider.
  VideoDetailsFetcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoDetailsFetcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoDetailsFetcherHash();

  @$internal
  @override
  VideoDetailsFetcher create() => VideoDetailsFetcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$videoDetailsFetcherHash() =>
    r'e5c9a6eceb19abc2ac395dfb3b661ef1a1215557';

/// Fetches details, such as descriptions, of videos asked for by ID, like
/// the watched videos AI is told about: signed in, while the quota lasts,
/// and only for those neither kept on this device nor known to be gone.
/// Each request is counted against the quota. Signed out, nothing is
/// fetched; what's kept is all there is.
///
/// A service: nothing depends on it, so it can read any provider.

abstract class _$VideoDetailsFetcher extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
