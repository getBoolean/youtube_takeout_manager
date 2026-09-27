// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_queue_groups.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The viewed channel's queue items [filter] shows, grouped by the channel
/// they were posted on: [firstChannelId]'s first, then the rest by name,
/// then items whose channel is unknown.
///
/// Here rather than in the deletion feature, which the channels feature
/// depends on, since it orders the groups by channel name.

@ProviderFor(deletionQueueGroups)
final deletionQueueGroupsProvider = DeletionQueueGroupsFamily._();

/// The viewed channel's queue items [filter] shows, grouped by the channel
/// they were posted on: [firstChannelId]'s first, then the rest by name,
/// then items whose channel is unknown.
///
/// Here rather than in the deletion feature, which the channels feature
/// depends on, since it orders the groups by channel name.

final class DeletionQueueGroupsProvider
    extends
        $FunctionalProvider<
          List<QueueChannelGroup>,
          List<QueueChannelGroup>,
          List<QueueChannelGroup>
        >
    with $Provider<List<QueueChannelGroup>> {
  /// The viewed channel's queue items [filter] shows, grouped by the channel
  /// they were posted on: [firstChannelId]'s first, then the rest by name,
  /// then items whose channel is unknown.
  ///
  /// Here rather than in the deletion feature, which the channels feature
  /// depends on, since it orders the groups by channel name.
  DeletionQueueGroupsProvider._({
    required DeletionQueueGroupsFamily super.from,
    required (DeletionQueueFilter, {String? firstChannelId}) super.argument,
  }) : super(
         retry: null,
         name: r'deletionQueueGroupsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deletionQueueGroupsHash();

  @override
  String toString() {
    return r'deletionQueueGroupsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<QueueChannelGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<QueueChannelGroup> create(Ref ref) {
    final argument =
        this.argument as (DeletionQueueFilter, {String? firstChannelId});
    return deletionQueueGroups(
      ref,
      argument.$1,
      firstChannelId: argument.firstChannelId,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<QueueChannelGroup> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<QueueChannelGroup>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DeletionQueueGroupsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deletionQueueGroupsHash() =>
    r'446c4920a8d1e99f708e5a3205fe82ce8b0c09b8';

/// The viewed channel's queue items [filter] shows, grouped by the channel
/// they were posted on: [firstChannelId]'s first, then the rest by name,
/// then items whose channel is unknown.
///
/// Here rather than in the deletion feature, which the channels feature
/// depends on, since it orders the groups by channel name.

final class DeletionQueueGroupsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          List<QueueChannelGroup>,
          (DeletionQueueFilter, {String? firstChannelId})
        > {
  DeletionQueueGroupsFamily._()
    : super(
        retry: null,
        name: r'deletionQueueGroupsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The viewed channel's queue items [filter] shows, grouped by the channel
  /// they were posted on: [firstChannelId]'s first, then the rest by name,
  /// then items whose channel is unknown.
  ///
  /// Here rather than in the deletion feature, which the channels feature
  /// depends on, since it orders the groups by channel name.

  DeletionQueueGroupsProvider call(
    DeletionQueueFilter filter, {
    String? firstChannelId,
  }) => DeletionQueueGroupsProvider._(
    argument: (filter, firstChannelId: firstChannelId),
    from: this,
  );

  @override
  String toString() => r'deletionQueueGroupsProvider';
}
