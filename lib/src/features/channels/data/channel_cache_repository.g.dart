// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_cache_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(channelCacheRepository)
final channelCacheRepositoryProvider = ChannelCacheRepositoryProvider._();

final class ChannelCacheRepositoryProvider
    extends
        $FunctionalProvider<
          ChannelCacheRepository,
          ChannelCacheRepository,
          ChannelCacheRepository
        >
    with $Provider<ChannelCacheRepository> {
  ChannelCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelCacheRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChannelCacheRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChannelCacheRepository create(Ref ref) {
    return channelCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChannelCacheRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChannelCacheRepository>(value),
    );
  }
}

String _$channelCacheRepositoryHash() =>
    r'81c38de32ed9f7985693910a2693a097c7ed2102';
