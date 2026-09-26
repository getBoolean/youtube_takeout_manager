// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewed_queue_items.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The queue items written by the viewed channel. Other channels' items wait
/// for their own channel to be viewed, since only its sign-in deletes them.

@ProviderFor(viewedQueueItems)
final viewedQueueItemsProvider = ViewedQueueItemsProvider._();

/// The queue items written by the viewed channel. Other channels' items wait
/// for their own channel to be viewed, since only its sign-in deletes them.

final class ViewedQueueItemsProvider
    extends
        $FunctionalProvider<
          List<DeletionQueueItem>,
          List<DeletionQueueItem>,
          List<DeletionQueueItem>
        >
    with $Provider<List<DeletionQueueItem>> {
  /// The queue items written by the viewed channel. Other channels' items wait
  /// for their own channel to be viewed, since only its sign-in deletes them.
  ViewedQueueItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewedQueueItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewedQueueItemsHash();

  @$internal
  @override
  $ProviderElement<List<DeletionQueueItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<DeletionQueueItem> create(Ref ref) {
    return viewedQueueItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DeletionQueueItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DeletionQueueItem>>(value),
    );
  }
}

String _$viewedQueueItemsHash() => r'31d1b583ddb3d0893e8a8e9acc391a0190a86fd4';

/// Items queued before their channel was saved that aren't done yet, and
/// that no loaded takeout has matched to a channel. They're never deleted
/// until one does.

@ProviderFor(unassignedQueueItems)
final unassignedQueueItemsProvider = UnassignedQueueItemsProvider._();

/// Items queued before their channel was saved that aren't done yet, and
/// that no loaded takeout has matched to a channel. They're never deleted
/// until one does.

final class UnassignedQueueItemsProvider
    extends
        $FunctionalProvider<
          List<DeletionQueueItem>,
          List<DeletionQueueItem>,
          List<DeletionQueueItem>
        >
    with $Provider<List<DeletionQueueItem>> {
  /// Items queued before their channel was saved that aren't done yet, and
  /// that no loaded takeout has matched to a channel. They're never deleted
  /// until one does.
  UnassignedQueueItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unassignedQueueItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unassignedQueueItemsHash();

  @$internal
  @override
  $ProviderElement<List<DeletionQueueItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<DeletionQueueItem> create(Ref ref) {
    return unassignedQueueItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DeletionQueueItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DeletionQueueItem>>(value),
    );
  }
}

String _$unassignedQueueItemsHash() =>
    r'4848242c0efb5944e68cbac4672eb62ff382dcd9';
