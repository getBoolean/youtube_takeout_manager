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

String _$filteredChannelsHash() => r'47ebc53dde84a9e3d020309f5766d57b6dd8550d';

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

String _$channelThumbnailsHash() => r'9d60cf693f861cc4405c90b41f0ef7236d8a7fe7';

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

@ProviderFor(channelById)
final channelByIdProvider = ChannelByIdFamily._();

final class ChannelByIdProvider
    extends $FunctionalProvider<Channel?, Channel?, Channel?>
    with $Provider<Channel?> {
  ChannelByIdProvider._({
    required ChannelByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'channelByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelByIdHash();

  @override
  String toString() {
    return r'channelByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Channel?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Channel? create(Ref ref) {
    final argument = this.argument as String;
    return channelById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Channel? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Channel?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelByIdHash() => r'14d5a19fc6f6cba71a5df228ceda3f14467e6341';

final class ChannelByIdFamily extends $Family
    with $FunctionalFamilyOverride<Channel?, String> {
  ChannelByIdFamily._()
    : super(
        retry: null,
        name: r'channelByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChannelByIdProvider call(String channelId) =>
      ChannelByIdProvider._(argument: channelId, from: this);

  @override
  String toString() => r'channelByIdProvider';
}
