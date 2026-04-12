// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChannelSearchQuery)
final channelSearchQueryProvider = ChannelSearchQueryProvider._();

final class ChannelSearchQueryProvider
    extends $NotifierProvider<ChannelSearchQuery, String> {
  ChannelSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelSearchQueryHash();

  @$internal
  @override
  ChannelSearchQuery create() => ChannelSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$channelSearchQueryHash() =>
    r'bf16702ca0d045ae3b771a57553a68006e69afc3';

abstract class _$ChannelSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredChannels)
final filteredChannelsProvider = FilteredChannelsProvider._();

final class FilteredChannelsProvider
    extends $FunctionalProvider<List<Channel>, List<Channel>, List<Channel>>
    with $Provider<List<Channel>> {
  FilteredChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredChannelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredChannelsHash();

  @$internal
  @override
  $ProviderElement<List<Channel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Channel> create(Ref ref) {
    return filteredChannels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Channel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Channel>>(value),
    );
  }
}

String _$filteredChannelsHash() => r'f0afa8ba402746c085252d06e07a1f25f9549e5c';

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

String _$channelsHash() => r'152e654e87c96ba0b53828c182accf9472df0905';
