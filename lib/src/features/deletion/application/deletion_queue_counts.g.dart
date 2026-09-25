// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_queue_counts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deletionQueueCounts)
final deletionQueueCountsProvider = DeletionQueueCountsProvider._();

final class DeletionQueueCountsProvider
    extends
        $FunctionalProvider<
          DeletionQueueCounts,
          DeletionQueueCounts,
          DeletionQueueCounts
        >
    with $Provider<DeletionQueueCounts> {
  DeletionQueueCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletionQueueCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletionQueueCountsHash();

  @$internal
  @override
  $ProviderElement<DeletionQueueCounts> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeletionQueueCounts create(Ref ref) {
    return deletionQueueCounts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeletionQueueCounts value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeletionQueueCounts>(value),
    );
  }
}

String _$deletionQueueCountsHash() =>
    r'504081cad4baafb8297eedad470fee171f97eae6';
