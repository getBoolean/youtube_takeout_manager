// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_category_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(channelCategoryRepository)
final channelCategoryRepositoryProvider = ChannelCategoryRepositoryProvider._();

final class ChannelCategoryRepositoryProvider
    extends
        $FunctionalProvider<
          ChannelCategoryRepository,
          ChannelCategoryRepository,
          ChannelCategoryRepository
        >
    with $Provider<ChannelCategoryRepository> {
  ChannelCategoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelCategoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelCategoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChannelCategoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChannelCategoryRepository create(Ref ref) {
    return channelCategoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChannelCategoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChannelCategoryRepository>(value),
    );
  }
}

String _$channelCategoryRepositoryHash() =>
    r'83b92135e5480e97633bde68644e13a9137d04c8';
