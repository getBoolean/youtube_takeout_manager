// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewed_takeout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The selected takeout's channels as the takeout names them, without
/// titles or pictures loaded since. Empty until it has loaded.

@ProviderFor(_takeoutChannelsAsImported)
final _takeoutChannelsAsImportedProvider =
    _TakeoutChannelsAsImportedProvider._();

/// The selected takeout's channels as the takeout names them, without
/// titles or pictures loaded since. Empty until it has loaded.

final class _TakeoutChannelsAsImportedProvider
    extends
        $FunctionalProvider<
          List<TakeoutChannel>,
          List<TakeoutChannel>,
          List<TakeoutChannel>
        >
    with $Provider<List<TakeoutChannel>> {
  /// The selected takeout's channels as the takeout names them, without
  /// titles or pictures loaded since. Empty until it has loaded.
  _TakeoutChannelsAsImportedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_takeoutChannelsAsImportedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_takeoutChannelsAsImportedHash();

  @$internal
  @override
  $ProviderElement<List<TakeoutChannel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TakeoutChannel> create(Ref ref) {
    return _takeoutChannelsAsImported(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TakeoutChannel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TakeoutChannel>>(value),
    );
  }
}

String _$_takeoutChannelsAsImportedHash() =>
    r'5a9117cd8acb2fafdd7d9472228c240f51abfaf3';

/// The selected takeout's channels, main first. Empty until it has loaded.

@ProviderFor(takeoutChannels)
final takeoutChannelsProvider = TakeoutChannelsProvider._();

/// The selected takeout's channels, main first. Empty until it has loaded.

final class TakeoutChannelsProvider
    extends
        $FunctionalProvider<
          List<TakeoutChannel>,
          List<TakeoutChannel>,
          List<TakeoutChannel>
        >
    with $Provider<List<TakeoutChannel>> {
  /// The selected takeout's channels, main first. Empty until it has loaded.
  TakeoutChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'takeoutChannelsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$takeoutChannelsHash();

  @$internal
  @override
  $ProviderElement<List<TakeoutChannel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TakeoutChannel> create(Ref ref) {
    return takeoutChannels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TakeoutChannel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TakeoutChannel>>(value),
    );
  }
}

String _$takeoutChannelsHash() => r'60182cdb8c242cb56e8eb78b00596b2c0770aed3';

/// Pictures for takeout channels: from saved sign-ins, else channel pictures
/// already loaded, by channel ID.

@ProviderFor(ownChannelThumbnails)
final ownChannelThumbnailsProvider = OwnChannelThumbnailsProvider._();

/// Pictures for takeout channels: from saved sign-ins, else channel pictures
/// already loaded, by channel ID.

final class OwnChannelThumbnailsProvider
    extends
        $FunctionalProvider<
          Map<String, String>,
          Map<String, String>,
          Map<String, String>
        >
    with $Provider<Map<String, String>> {
  /// Pictures for takeout channels: from saved sign-ins, else channel pictures
  /// already loaded, by channel ID.
  OwnChannelThumbnailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownChannelThumbnailsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownChannelThumbnailsHash();

  @$internal
  @override
  $ProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, String> create(Ref ref) {
    return ownChannelThumbnails(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$ownChannelThumbnailsHash() =>
    r'c4a2c628dd9fd13079fa790587f922803a3911e6';

/// The ID of the channel being viewed: the one last chosen in the selected
/// takeout while it's still there, otherwise the takeout's main channel.
///
/// Worked out without channel titles or pictures, so what depends on it,
/// like the sign-in used to fetch pictures, doesn't depend on those too.

@ProviderFor(viewedChannelId)
final viewedChannelIdProvider = ViewedChannelIdProvider._();

/// The ID of the channel being viewed: the one last chosen in the selected
/// takeout while it's still there, otherwise the takeout's main channel.
///
/// Worked out without channel titles or pictures, so what depends on it,
/// like the sign-in used to fetch pictures, doesn't depend on those too.

final class ViewedChannelIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The ID of the channel being viewed: the one last chosen in the selected
  /// takeout while it's still there, otherwise the takeout's main channel.
  ///
  /// Worked out without channel titles or pictures, so what depends on it,
  /// like the sign-in used to fetch pictures, doesn't depend on those too.
  ViewedChannelIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewedChannelIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewedChannelIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return viewedChannelId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$viewedChannelIdHash() => r'2078e614fb03a4f5252e6481f36a9988583d00f3';

/// The channel being viewed, with its title and picture.

@ProviderFor(viewedChannel)
final viewedChannelProvider = ViewedChannelProvider._();

/// The channel being viewed, with its title and picture.

final class ViewedChannelProvider
    extends
        $FunctionalProvider<TakeoutChannel?, TakeoutChannel?, TakeoutChannel?>
    with $Provider<TakeoutChannel?> {
  /// The channel being viewed, with its title and picture.
  ViewedChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewedChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewedChannelHash();

  @$internal
  @override
  $ProviderElement<TakeoutChannel?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TakeoutChannel? create(Ref ref) {
    return viewedChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TakeoutChannel? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TakeoutChannel?>(value),
    );
  }
}

String _$viewedChannelHash() => r'4792219faddd89a521e9302d6bf7d184686ede04';

/// The viewed channel's comments and live chats from the selected takeout.
///
/// Plainly loading, without the previous takeout's data, while another
/// takeout loads, so the old one never shows as the new one. (Async
/// providers keep their previous value while they reload.)

@ProviderFor(viewedTakeout)
final viewedTakeoutProvider = ViewedTakeoutProvider._();

/// The viewed channel's comments and live chats from the selected takeout.
///
/// Plainly loading, without the previous takeout's data, while another
/// takeout loads, so the old one never shows as the new one. (Async
/// providers keep their previous value while they reload.)

final class ViewedTakeoutProvider
    extends
        $FunctionalProvider<
          AsyncValue<TakeoutData?>,
          AsyncValue<TakeoutData?>,
          AsyncValue<TakeoutData?>
        >
    with $Provider<AsyncValue<TakeoutData?>> {
  /// The viewed channel's comments and live chats from the selected takeout.
  ///
  /// Plainly loading, without the previous takeout's data, while another
  /// takeout loads, so the old one never shows as the new one. (Async
  /// providers keep their previous value while they reload.)
  ViewedTakeoutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewedTakeoutProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewedTakeoutHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<TakeoutData?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<TakeoutData?> create(Ref ref) {
    return viewedTakeout(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<TakeoutData?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<TakeoutData?>>(value),
    );
  }
}

String _$viewedTakeoutHash() => r'd4d1067f57a0fc4765f07146deef100e83f17b11';
