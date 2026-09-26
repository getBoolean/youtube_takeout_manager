// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewed_takeout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$takeoutChannelsHash() => r'd9b3c6072329ca4ecf68e277486fb9033d1ad7cc';

/// The channel being viewed: the one last chosen in the selected takeout
/// while it's still there, otherwise the takeout's main channel.

@ProviderFor(viewedChannel)
final viewedChannelProvider = ViewedChannelProvider._();

/// The channel being viewed: the one last chosen in the selected takeout
/// while it's still there, otherwise the takeout's main channel.

final class ViewedChannelProvider
    extends
        $FunctionalProvider<TakeoutChannel?, TakeoutChannel?, TakeoutChannel?>
    with $Provider<TakeoutChannel?> {
  /// The channel being viewed: the one last chosen in the selected takeout
  /// while it's still there, otherwise the takeout's main channel.
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

String _$viewedChannelHash() => r'7b86a6c328d7bd83707b3d72a22f3d3b9510b025';

@ProviderFor(viewedChannelId)
final viewedChannelIdProvider = ViewedChannelIdProvider._();

final class ViewedChannelIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
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

String _$viewedChannelIdHash() => r'5a11e807466db9b090b7ba5cba770729c1a59849';

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
