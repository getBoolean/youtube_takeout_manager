// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_details_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(channelDetailsRepository)
final channelDetailsRepositoryProvider = ChannelDetailsRepositoryProvider._();

final class ChannelDetailsRepositoryProvider
    extends
        $FunctionalProvider<
          ChannelDetailsRepository,
          ChannelDetailsRepository,
          ChannelDetailsRepository
        >
    with $Provider<ChannelDetailsRepository> {
  ChannelDetailsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelDetailsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelDetailsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChannelDetailsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChannelDetailsRepository create(Ref ref) {
    return channelDetailsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChannelDetailsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChannelDetailsRepository>(value),
    );
  }
}

String _$channelDetailsRepositoryHash() =>
    r'428fb2a779def33e6deb1ccc8b04306d27d7540f';
