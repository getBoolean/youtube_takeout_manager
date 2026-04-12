// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(channels)
final channelsProvider = ChannelsProvider._();

final class ChannelsProvider
    extends $FunctionalProvider<List<Channel>, List<Channel>, List<Channel>>
    with $Provider<List<Channel>> {
  ChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelsHash();

  @$internal
  @override
  $ProviderElement<List<Channel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Channel> create(Ref ref) {
    return channels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Channel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Channel>>(value),
    );
  }
}

String _$channelsHash() => r'693d98a2d21e4a49d5bcf870648bb929c50617a1';
