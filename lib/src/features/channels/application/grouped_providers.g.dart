// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grouped_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [kind]'s items on [channelId]'s videos, grouped by video.

@ProviderFor(groupedChannelInteractions)
final groupedChannelInteractionsProvider = GroupedChannelInteractionsFamily._();

/// [kind]'s items on [channelId]'s videos, grouped by video.

final class GroupedChannelInteractionsProvider
    extends
        $FunctionalProvider<
          List<VideoGroup<Interaction>>,
          List<VideoGroup<Interaction>>,
          List<VideoGroup<Interaction>>
        >
    with $Provider<List<VideoGroup<Interaction>>> {
  /// [kind]'s items on [channelId]'s videos, grouped by video.
  GroupedChannelInteractionsProvider._({
    required GroupedChannelInteractionsFamily super.from,
    required (QueueItemKind, String) super.argument,
  }) : super(
         retry: null,
         name: r'groupedChannelInteractionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupedChannelInteractionsHash();

  @override
  String toString() {
    return r'groupedChannelInteractionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<VideoGroup<Interaction>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<VideoGroup<Interaction>> create(Ref ref) {
    final argument = this.argument as (QueueItemKind, String);
    return groupedChannelInteractions(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<VideoGroup<Interaction>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<VideoGroup<Interaction>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GroupedChannelInteractionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupedChannelInteractionsHash() =>
    r'1958ecb01ef6ee8fa380ec039cd782b8bae4df3b';

/// [kind]'s items on [channelId]'s videos, grouped by video.

final class GroupedChannelInteractionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          List<VideoGroup<Interaction>>,
          (QueueItemKind, String)
        > {
  GroupedChannelInteractionsFamily._()
    : super(
        retry: null,
        name: r'groupedChannelInteractionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [kind]'s items on [channelId]'s videos, grouped by video.

  GroupedChannelInteractionsProvider call(
    QueueItemKind kind,
    String channelId,
  ) => GroupedChannelInteractionsProvider._(
    argument: (kind, channelId),
    from: this,
  );

  @override
  String toString() => r'groupedChannelInteractionsProvider';
}

/// The groups of [groupedChannelInteractionsProvider] that match the channel
/// search: by group title, or by the text of their items.

@ProviderFor(filteredGroupedChannelInteractions)
final filteredGroupedChannelInteractionsProvider =
    FilteredGroupedChannelInteractionsFamily._();

/// The groups of [groupedChannelInteractionsProvider] that match the channel
/// search: by group title, or by the text of their items.

final class FilteredGroupedChannelInteractionsProvider
    extends
        $FunctionalProvider<
          List<VideoGroup<Interaction>>,
          List<VideoGroup<Interaction>>,
          List<VideoGroup<Interaction>>
        >
    with $Provider<List<VideoGroup<Interaction>>> {
  /// The groups of [groupedChannelInteractionsProvider] that match the channel
  /// search: by group title, or by the text of their items.
  FilteredGroupedChannelInteractionsProvider._({
    required FilteredGroupedChannelInteractionsFamily super.from,
    required (QueueItemKind, String) super.argument,
  }) : super(
         retry: null,
         name: r'filteredGroupedChannelInteractionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$filteredGroupedChannelInteractionsHash();

  @override
  String toString() {
    return r'filteredGroupedChannelInteractionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<VideoGroup<Interaction>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<VideoGroup<Interaction>> create(Ref ref) {
    final argument = this.argument as (QueueItemKind, String);
    return filteredGroupedChannelInteractions(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<VideoGroup<Interaction>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<VideoGroup<Interaction>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredGroupedChannelInteractionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredGroupedChannelInteractionsHash() =>
    r'de85a62df6d3527cdf1de68cf199d30ac015655a';

/// The groups of [groupedChannelInteractionsProvider] that match the channel
/// search: by group title, or by the text of their items.

final class FilteredGroupedChannelInteractionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          List<VideoGroup<Interaction>>,
          (QueueItemKind, String)
        > {
  FilteredGroupedChannelInteractionsFamily._()
    : super(
        retry: null,
        name: r'filteredGroupedChannelInteractionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The groups of [groupedChannelInteractionsProvider] that match the channel
  /// search: by group title, or by the text of their items.

  FilteredGroupedChannelInteractionsProvider call(
    QueueItemKind kind,
    String channelId,
  ) => FilteredGroupedChannelInteractionsProvider._(
    argument: (kind, channelId),
    from: this,
  );

  @override
  String toString() => r'filteredGroupedChannelInteractionsProvider';
}

/// Flat list of [kind]'s items currently visible in search results,
/// excluding any already marked as deleted. Empty when the search query is
/// empty.

@ProviderFor(filteredSearchInteractions)
final filteredSearchInteractionsProvider = FilteredSearchInteractionsFamily._();

/// Flat list of [kind]'s items currently visible in search results,
/// excluding any already marked as deleted. Empty when the search query is
/// empty.

final class FilteredSearchInteractionsProvider
    extends
        $FunctionalProvider<
          List<Interaction>,
          List<Interaction>,
          List<Interaction>
        >
    with $Provider<List<Interaction>> {
  /// Flat list of [kind]'s items currently visible in search results,
  /// excluding any already marked as deleted. Empty when the search query is
  /// empty.
  FilteredSearchInteractionsProvider._({
    required FilteredSearchInteractionsFamily super.from,
    required (QueueItemKind, String) super.argument,
  }) : super(
         retry: null,
         name: r'filteredSearchInteractionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredSearchInteractionsHash();

  @override
  String toString() {
    return r'filteredSearchInteractionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<Interaction>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Interaction> create(Ref ref) {
    final argument = this.argument as (QueueItemKind, String);
    return filteredSearchInteractions(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Interaction> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Interaction>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredSearchInteractionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredSearchInteractionsHash() =>
    r'02a2c73fc90eada8053a56ca793a75b730ed6f3e';

/// Flat list of [kind]'s items currently visible in search results,
/// excluding any already marked as deleted. Empty when the search query is
/// empty.

final class FilteredSearchInteractionsFamily extends $Family
    with $FunctionalFamilyOverride<List<Interaction>, (QueueItemKind, String)> {
  FilteredSearchInteractionsFamily._()
    : super(
        retry: null,
        name: r'filteredSearchInteractionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Flat list of [kind]'s items currently visible in search results,
  /// excluding any already marked as deleted. Empty when the search query is
  /// empty.

  FilteredSearchInteractionsProvider call(
    QueueItemKind kind,
    String channelId,
  ) => FilteredSearchInteractionsProvider._(
    argument: (kind, channelId),
    from: this,
  );

  @override
  String toString() => r'filteredSearchInteractionsProvider';
}
