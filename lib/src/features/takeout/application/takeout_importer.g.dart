// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeout_importer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Imports takeouts: works out what picked zips would change, then saves
/// them, marking what they found gone. A service: nothing depends on it, so
/// it can read any provider.

@ProviderFor(TakeoutImporter)
final takeoutImporterProvider = TakeoutImporterProvider._();

/// Imports takeouts: works out what picked zips would change, then saves
/// them, marking what they found gone. A service: nothing depends on it, so
/// it can read any provider.
final class TakeoutImporterProvider
    extends $NotifierProvider<TakeoutImporter, void> {
  /// Imports takeouts: works out what picked zips would change, then saves
  /// them, marking what they found gone. A service: nothing depends on it, so
  /// it can read any provider.
  TakeoutImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'takeoutImporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$takeoutImporterHash();

  @$internal
  @override
  TakeoutImporter create() => TakeoutImporter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$takeoutImporterHash() => r'4b167ccbf36b9798acd363c077281f900df5ddbd';

/// Imports takeouts: works out what picked zips would change, then saves
/// them, marking what they found gone. A service: nothing depends on it, so
/// it can read any provider.

abstract class _$TakeoutImporter extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fills in the channel of queued deletions saved before it was, each time
/// a takeout loads. An effect, started with the app.

@ProviderFor(queueChannelAssignment)
final queueChannelAssignmentProvider = QueueChannelAssignmentProvider._();

/// Fills in the channel of queued deletions saved before it was, each time
/// a takeout loads. An effect, started with the app.

final class QueueChannelAssignmentProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Fills in the channel of queued deletions saved before it was, each time
  /// a takeout loads. An effect, started with the app.
  QueueChannelAssignmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'queueChannelAssignmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$queueChannelAssignmentHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return queueChannelAssignment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$queueChannelAssignmentHash() =>
    r'67fa1a961e4cf6e30cafa264af5ee23cced4c23b';
