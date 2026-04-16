// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_channel_search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Comments + live chats across every channel whose display text contains the
/// current [channelSearchQueryProvider] value, sorted newest first. Excludes
/// items already persisted as deleted. Empty when the query is empty.

@ProviderFor(crossChannelSearchItems)
final crossChannelSearchItemsProvider = CrossChannelSearchItemsProvider._();

/// Comments + live chats across every channel whose display text contains the
/// current [channelSearchQueryProvider] value, sorted newest first. Excludes
/// items already persisted as deleted. Empty when the query is empty.

final class CrossChannelSearchItemsProvider
    extends
        $FunctionalProvider<
          List<SearchResultItem>,
          List<SearchResultItem>,
          List<SearchResultItem>
        >
    with $Provider<List<SearchResultItem>> {
  /// Comments + live chats across every channel whose display text contains the
  /// current [channelSearchQueryProvider] value, sorted newest first. Excludes
  /// items already persisted as deleted. Empty when the query is empty.
  CrossChannelSearchItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crossChannelSearchItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crossChannelSearchItemsHash();

  @$internal
  @override
  $ProviderElement<List<SearchResultItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SearchResultItem> create(Ref ref) {
    return crossChannelSearchItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SearchResultItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SearchResultItem>>(value),
    );
  }
}

String _$crossChannelSearchItemsHash() =>
    r'227195d3682344d12f0bfdf7380c387cbc19ef83';

/// Subset of [crossChannelSearchItemsProvider] that is eligible for bulk
/// deletion — strips items already in the deletion queue (pending/in-progress)
/// or currently failed.

@ProviderFor(crossChannelDeletableItems)
final crossChannelDeletableItemsProvider =
    CrossChannelDeletableItemsProvider._();

/// Subset of [crossChannelSearchItemsProvider] that is eligible for bulk
/// deletion — strips items already in the deletion queue (pending/in-progress)
/// or currently failed.

final class CrossChannelDeletableItemsProvider
    extends
        $FunctionalProvider<
          List<SearchResultItem>,
          List<SearchResultItem>,
          List<SearchResultItem>
        >
    with $Provider<List<SearchResultItem>> {
  /// Subset of [crossChannelSearchItemsProvider] that is eligible for bulk
  /// deletion — strips items already in the deletion queue (pending/in-progress)
  /// or currently failed.
  CrossChannelDeletableItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crossChannelDeletableItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crossChannelDeletableItemsHash();

  @$internal
  @override
  $ProviderElement<List<SearchResultItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SearchResultItem> create(Ref ref) {
    return crossChannelDeletableItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SearchResultItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SearchResultItem>>(value),
    );
  }
}

String _$crossChannelDeletableItemsHash() =>
    r'ecb0f91243b0a3e0d3238146e53ec61d85d03ac8';
