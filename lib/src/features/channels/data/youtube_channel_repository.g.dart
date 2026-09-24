// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_channel_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(youtubeChannelRepository)
final youtubeChannelRepositoryProvider = YoutubeChannelRepositoryProvider._();

final class YoutubeChannelRepositoryProvider
    extends
        $FunctionalProvider<
          YoutubeChannelRepository,
          YoutubeChannelRepository,
          YoutubeChannelRepository
        >
    with $Provider<YoutubeChannelRepository> {
  YoutubeChannelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'youtubeChannelRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$youtubeChannelRepositoryHash();

  @$internal
  @override
  $ProviderElement<YoutubeChannelRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  YoutubeChannelRepository create(Ref ref) {
    return youtubeChannelRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(YoutubeChannelRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<YoutubeChannelRepository>(value),
    );
  }
}

String _$youtubeChannelRepositoryHash() =>
    r'04d53559f0c1e860406e83d6d8618d6409313681';
