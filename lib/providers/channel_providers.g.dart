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

@ProviderFor(channelTitlesFromVideos)
final channelTitlesFromVideosProvider = ChannelTitlesFromVideosProvider._();

final class ChannelTitlesFromVideosProvider
    extends
        $FunctionalProvider<
          Map<String, String>,
          Map<String, String>,
          Map<String, String>
        >
    with $Provider<Map<String, String>> {
  ChannelTitlesFromVideosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelTitlesFromVideosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelTitlesFromVideosHash();

  @$internal
  @override
  $ProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, String> create(Ref ref) {
    return channelTitlesFromVideos(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$channelTitlesFromVideosHash() =>
    r'ed393773d249f269882c15519e293baf03011288';

@ProviderFor(ChannelThumbnails)
final channelThumbnailsProvider = ChannelThumbnailsProvider._();

final class ChannelThumbnailsProvider
    extends $NotifierProvider<ChannelThumbnails, Map<String, String>> {
  ChannelThumbnailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelThumbnailsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelThumbnailsHash();

  @$internal
  @override
  ChannelThumbnails create() => ChannelThumbnails();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$channelThumbnailsHash() => r'a5a5222537ae67b2fe24ef4a58d4f14e2f17602b';

abstract class _$ChannelThumbnails extends $Notifier<Map<String, String>> {
  Map<String, String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, String>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, String>, Map<String, String>>,
              Map<String, String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

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

String _$channelsHash() => r'31beddcd8fae022e129a60f10a41807478d17cb6';
