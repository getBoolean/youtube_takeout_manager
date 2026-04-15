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
         isAutoDispose: false,
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
    r'aeac947bb71dd8ef204f328ed3e8bcb5230abb6f';

final class GroupedChannelCommentsFamily extends $Family
    with $FunctionalFamilyOverride<List<VideoGroup<Comment>>, String> {
  GroupedChannelCommentsFamily._()
    : super(
        retry: null,
        name: r'groupedChannelCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
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
         isAutoDispose: false,
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
    r'3903c952fbf5be4a8b8e4669aef7594f07a6ebb6';

final class GroupedChannelLiveChatsFamily extends $Family
    with $FunctionalFamilyOverride<List<VideoGroup<LiveChat>>, String> {
  GroupedChannelLiveChatsFamily._()
    : super(
        retry: null,
        name: r'groupedChannelLiveChatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  GroupedChannelLiveChatsProvider call(String channelId) =>
      GroupedChannelLiveChatsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'groupedChannelLiveChatsProvider';
}
