// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_thumbnail_fetcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches channel pictures, and with them each channel's topics and
/// description, at no extra cost: for the channels the viewed channel
/// interacted with, once [thumbnailBatchSize] of them appear and the rest
/// once video titles are done; whole lists at once, such as history's
/// channels, with [fetchNow], the channels on screen first ([fetchFirst]);
/// and, with [fetchDetails], channels whose details are wanted though they
/// have a picture. Each request is counted against the quota; channels
/// YouTube has no picture for are remembered and not asked for again.
/// Signed out, nothing is fetched.
/// An effect: nothing depends on it, so it can read any provider.

@ProviderFor(ChannelThumbnailFetcher)
final channelThumbnailFetcherProvider = ChannelThumbnailFetcherProvider._();

/// Fetches channel pictures, and with them each channel's topics and
/// description, at no extra cost: for the channels the viewed channel
/// interacted with, once [thumbnailBatchSize] of them appear and the rest
/// once video titles are done; whole lists at once, such as history's
/// channels, with [fetchNow], the channels on screen first ([fetchFirst]);
/// and, with [fetchDetails], channels whose details are wanted though they
/// have a picture. Each request is counted against the quota; channels
/// YouTube has no picture for are remembered and not asked for again.
/// Signed out, nothing is fetched.
/// An effect: nothing depends on it, so it can read any provider.
final class ChannelThumbnailFetcherProvider
    extends $NotifierProvider<ChannelThumbnailFetcher, void> {
  /// Fetches channel pictures, and with them each channel's topics and
  /// description, at no extra cost: for the channels the viewed channel
  /// interacted with, once [thumbnailBatchSize] of them appear and the rest
  /// once video titles are done; whole lists at once, such as history's
  /// channels, with [fetchNow], the channels on screen first ([fetchFirst]);
  /// and, with [fetchDetails], channels whose details are wanted though they
  /// have a picture. Each request is counted against the quota; channels
  /// YouTube has no picture for are remembered and not asked for again.
  /// Signed out, nothing is fetched.
  /// An effect: nothing depends on it, so it can read any provider.
  ChannelThumbnailFetcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelThumbnailFetcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelThumbnailFetcherHash();

  @$internal
  @override
  ChannelThumbnailFetcher create() => ChannelThumbnailFetcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$channelThumbnailFetcherHash() =>
    r'b069e19054add6f52bd35143bb2af4aa39f98a4d';

/// Fetches channel pictures, and with them each channel's topics and
/// description, at no extra cost: for the channels the viewed channel
/// interacted with, once [thumbnailBatchSize] of them appear and the rest
/// once video titles are done; whole lists at once, such as history's
/// channels, with [fetchNow], the channels on screen first ([fetchFirst]);
/// and, with [fetchDetails], channels whose details are wanted though they
/// have a picture. Each request is counted against the quota; channels
/// YouTube has no picture for are remembered and not asked for again.
/// Signed out, nothing is fetched.
/// An effect: nothing depends on it, so it can read any provider.

abstract class _$ChannelThumbnailFetcher extends $Notifier<void> {
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
