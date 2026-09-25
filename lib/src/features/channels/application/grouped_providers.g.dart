// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grouped_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(groupedChannelComments)
final groupedChannelCommentsProvider = GroupedChannelCommentsFamily._();

final class GroupedChannelCommentsProvider
    extends
        $FunctionalProvider<
          List<VideoGroup<Comment>>,
          List<VideoGroup<Comment>>,
          List<VideoGroup<Comment>>
        >
    with $Provider<List<VideoGroup<Comment>>> {
  GroupedChannelCommentsProvider._({
    required GroupedChannelCommentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupedChannelCommentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupedChannelCommentsHash();

  @override
  String toString() {
    return r'groupedChannelCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<VideoGroup<Comment>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<VideoGroup<Comment>> create(Ref ref) {
    final argument = this.argument as String;
    return groupedChannelComments(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<VideoGroup<Comment>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<VideoGroup<Comment>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GroupedChannelCommentsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupedChannelCommentsHash() =>
    r'e33c2d5520a8d8ede0aed0fd2a0100c5a62acca7';

final class GroupedChannelCommentsFamily extends $Family
    with $FunctionalFamilyOverride<List<VideoGroup<Comment>>, String> {
  GroupedChannelCommentsFamily._()
    : super(
        retry: null,
        name: r'groupedChannelCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GroupedChannelCommentsProvider call(String channelId) =>
      GroupedChannelCommentsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'groupedChannelCommentsProvider';
}

@ProviderFor(groupedChannelLiveChats)
final groupedChannelLiveChatsProvider = GroupedChannelLiveChatsFamily._();

final class GroupedChannelLiveChatsProvider
    extends
        $FunctionalProvider<
          List<VideoGroup<LiveChat>>,
          List<VideoGroup<LiveChat>>,
          List<VideoGroup<LiveChat>>
        >
    with $Provider<List<VideoGroup<LiveChat>>> {
  GroupedChannelLiveChatsProvider._({
    required GroupedChannelLiveChatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupedChannelLiveChatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupedChannelLiveChatsHash();

  @override
  String toString() {
    return r'groupedChannelLiveChatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<VideoGroup<LiveChat>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<VideoGroup<LiveChat>> create(Ref ref) {
    final argument = this.argument as String;
    return groupedChannelLiveChats(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<VideoGroup<LiveChat>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<VideoGroup<LiveChat>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GroupedChannelLiveChatsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupedChannelLiveChatsHash() =>
    r'4031931181184de1637884f0ccb27f41925bf1ae';

final class GroupedChannelLiveChatsFamily extends $Family
    with $FunctionalFamilyOverride<List<VideoGroup<LiveChat>>, String> {
  GroupedChannelLiveChatsFamily._()
    : super(
        retry: null,
        name: r'groupedChannelLiveChatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GroupedChannelLiveChatsProvider call(String channelId) =>
      GroupedChannelLiveChatsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'groupedChannelLiveChatsProvider';
}

@ProviderFor(filteredGroupedChannelComments)
final filteredGroupedChannelCommentsProvider =
    FilteredGroupedChannelCommentsFamily._();

final class FilteredGroupedChannelCommentsProvider
    extends
        $FunctionalProvider<
          List<VideoGroup<Comment>>,
          List<VideoGroup<Comment>>,
          List<VideoGroup<Comment>>
        >
    with $Provider<List<VideoGroup<Comment>>> {
  FilteredGroupedChannelCommentsProvider._({
    required FilteredGroupedChannelCommentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredGroupedChannelCommentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredGroupedChannelCommentsHash();

  @override
  String toString() {
    return r'filteredGroupedChannelCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<VideoGroup<Comment>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<VideoGroup<Comment>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredGroupedChannelComments(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<VideoGroup<Comment>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<VideoGroup<Comment>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredGroupedChannelCommentsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredGroupedChannelCommentsHash() =>
    r'27eb474734e04561f11c1616d3b18970f6769bd5';

final class FilteredGroupedChannelCommentsFamily extends $Family
    with $FunctionalFamilyOverride<List<VideoGroup<Comment>>, String> {
  FilteredGroupedChannelCommentsFamily._()
    : super(
        retry: null,
        name: r'filteredGroupedChannelCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredGroupedChannelCommentsProvider call(String channelId) =>
      FilteredGroupedChannelCommentsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'filteredGroupedChannelCommentsProvider';
}

@ProviderFor(filteredGroupedChannelLiveChats)
final filteredGroupedChannelLiveChatsProvider =
    FilteredGroupedChannelLiveChatsFamily._();

final class FilteredGroupedChannelLiveChatsProvider
    extends
        $FunctionalProvider<
          List<VideoGroup<LiveChat>>,
          List<VideoGroup<LiveChat>>,
          List<VideoGroup<LiveChat>>
        >
    with $Provider<List<VideoGroup<LiveChat>>> {
  FilteredGroupedChannelLiveChatsProvider._({
    required FilteredGroupedChannelLiveChatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredGroupedChannelLiveChatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredGroupedChannelLiveChatsHash();

  @override
  String toString() {
    return r'filteredGroupedChannelLiveChatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<VideoGroup<LiveChat>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<VideoGroup<LiveChat>> create(Ref ref) {
    final argument = this.argument as String;
    return filteredGroupedChannelLiveChats(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<VideoGroup<LiveChat>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<VideoGroup<LiveChat>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredGroupedChannelLiveChatsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredGroupedChannelLiveChatsHash() =>
    r'678630a7d440e9d7bea637410ffffc61a7003c6f';

final class FilteredGroupedChannelLiveChatsFamily extends $Family
    with $FunctionalFamilyOverride<List<VideoGroup<LiveChat>>, String> {
  FilteredGroupedChannelLiveChatsFamily._()
    : super(
        retry: null,
        name: r'filteredGroupedChannelLiveChatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredGroupedChannelLiveChatsProvider call(String channelId) =>
      FilteredGroupedChannelLiveChatsProvider._(
        argument: channelId,
        from: this,
      );

  @override
  String toString() => r'filteredGroupedChannelLiveChatsProvider';
}

/// Flat list of comments currently visible in search results, excluding any
/// already marked as deleted. Empty when the search query is empty.

@ProviderFor(filteredSearchComments)
final filteredSearchCommentsProvider = FilteredSearchCommentsFamily._();

/// Flat list of comments currently visible in search results, excluding any
/// already marked as deleted. Empty when the search query is empty.

final class FilteredSearchCommentsProvider
    extends $FunctionalProvider<List<Comment>, List<Comment>, List<Comment>>
    with $Provider<List<Comment>> {
  /// Flat list of comments currently visible in search results, excluding any
  /// already marked as deleted. Empty when the search query is empty.
  FilteredSearchCommentsProvider._({
    required FilteredSearchCommentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredSearchCommentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredSearchCommentsHash();

  @override
  String toString() {
    return r'filteredSearchCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Comment>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Comment> create(Ref ref) {
    final argument = this.argument as String;
    return filteredSearchComments(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Comment> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Comment>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredSearchCommentsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredSearchCommentsHash() =>
    r'01bde5f486c456ab747d1ff0420d9ee7616c6899';

/// Flat list of comments currently visible in search results, excluding any
/// already marked as deleted. Empty when the search query is empty.

final class FilteredSearchCommentsFamily extends $Family
    with $FunctionalFamilyOverride<List<Comment>, String> {
  FilteredSearchCommentsFamily._()
    : super(
        retry: null,
        name: r'filteredSearchCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Flat list of comments currently visible in search results, excluding any
  /// already marked as deleted. Empty when the search query is empty.

  FilteredSearchCommentsProvider call(String channelId) =>
      FilteredSearchCommentsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'filteredSearchCommentsProvider';
}

/// Flat list of live chats currently visible in search results, excluding any
/// already marked as deleted. Empty when the search query is empty.

@ProviderFor(filteredSearchLiveChats)
final filteredSearchLiveChatsProvider = FilteredSearchLiveChatsFamily._();

/// Flat list of live chats currently visible in search results, excluding any
/// already marked as deleted. Empty when the search query is empty.

final class FilteredSearchLiveChatsProvider
    extends $FunctionalProvider<List<LiveChat>, List<LiveChat>, List<LiveChat>>
    with $Provider<List<LiveChat>> {
  /// Flat list of live chats currently visible in search results, excluding any
  /// already marked as deleted. Empty when the search query is empty.
  FilteredSearchLiveChatsProvider._({
    required FilteredSearchLiveChatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredSearchLiveChatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredSearchLiveChatsHash();

  @override
  String toString() {
    return r'filteredSearchLiveChatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<LiveChat>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<LiveChat> create(Ref ref) {
    final argument = this.argument as String;
    return filteredSearchLiveChats(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LiveChat> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LiveChat>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredSearchLiveChatsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredSearchLiveChatsHash() =>
    r'5dd328f66d27a4f5fbd74418f1d235c70580b4be';

/// Flat list of live chats currently visible in search results, excluding any
/// already marked as deleted. Empty when the search query is empty.

final class FilteredSearchLiveChatsFamily extends $Family
    with $FunctionalFamilyOverride<List<LiveChat>, String> {
  FilteredSearchLiveChatsFamily._()
    : super(
        retry: null,
        name: r'filteredSearchLiveChatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Flat list of live chats currently visible in search results, excluding any
  /// already marked as deleted. Empty when the search query is empty.

  FilteredSearchLiveChatsProvider call(String channelId) =>
      FilteredSearchLiveChatsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'filteredSearchLiveChatsProvider';
}
