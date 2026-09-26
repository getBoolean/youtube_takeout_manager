// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signed_in_channels.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Titles of the channels with a saved sign-in, by channel ID, from the
/// YouTube API at sign-in. Names takeout channels their saved data gives no
/// title, e.g. data saved before channel lists were kept.

@ProviderFor(signedInChannelTitles)
final signedInChannelTitlesProvider = SignedInChannelTitlesProvider._();

/// Titles of the channels with a saved sign-in, by channel ID, from the
/// YouTube API at sign-in. Names takeout channels their saved data gives no
/// title, e.g. data saved before channel lists were kept.

final class SignedInChannelTitlesProvider
    extends
        $FunctionalProvider<
          Map<String, String>,
          Map<String, String>,
          Map<String, String>
        >
    with $Provider<Map<String, String>> {
  /// Titles of the channels with a saved sign-in, by channel ID, from the
  /// YouTube API at sign-in. Names takeout channels their saved data gives no
  /// title, e.g. data saved before channel lists were kept.
  SignedInChannelTitlesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signedInChannelTitlesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signedInChannelTitlesHash();

  @$internal
  @override
  $ProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, String> create(Ref ref) {
    return signedInChannelTitles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$signedInChannelTitlesHash() =>
    r'cf935e9224929d9614795f91475d4ea2fc71cbc0';

/// Pictures of the channels with a saved sign-in, by channel ID, from the
/// YouTube API at sign-in.

@ProviderFor(signedInChannelThumbnails)
final signedInChannelThumbnailsProvider = SignedInChannelThumbnailsProvider._();

/// Pictures of the channels with a saved sign-in, by channel ID, from the
/// YouTube API at sign-in.

final class SignedInChannelThumbnailsProvider
    extends
        $FunctionalProvider<
          Map<String, String>,
          Map<String, String>,
          Map<String, String>
        >
    with $Provider<Map<String, String>> {
  /// Pictures of the channels with a saved sign-in, by channel ID, from the
  /// YouTube API at sign-in.
  SignedInChannelThumbnailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signedInChannelThumbnailsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signedInChannelThumbnailsHash();

  @$internal
  @override
  $ProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, String> create(Ref ref) {
    return signedInChannelThumbnails(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$signedInChannelThumbnailsHash() =>
    r'9ab49eb90eb9e06651d06613c524789711286ca9';
