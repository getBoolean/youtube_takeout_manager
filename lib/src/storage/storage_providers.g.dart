// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The storage worker, started on first use. Its first start moves the
/// blobs kept in key-value storage into boxes, once.

@ProviderFor(workerStorage)
final workerStorageProvider = WorkerStorageProvider._();

/// The storage worker, started on first use. Its first start moves the
/// blobs kept in key-value storage into boxes, once.

final class WorkerStorageProvider
    extends $FunctionalProvider<WorkerStorage, WorkerStorage, WorkerStorage>
    with $Provider<WorkerStorage> {
  /// The storage worker, started on first use. Its first start moves the
  /// blobs kept in key-value storage into boxes, once.
  WorkerStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workerStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workerStorageHash();

  @$internal
  @override
  $ProviderElement<WorkerStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WorkerStorage create(Ref ref) {
    return workerStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkerStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkerStorage>(value),
    );
  }
}

String _$workerStorageHash() => r'6342d71bb25f6b4b1f87bc3f7c28375049dcbed9';

/// Where bulk data is kept: the storage worker, or memory in tests.

@ProviderFor(entryStore)
final entryStoreProvider = EntryStoreProvider._();

/// Where bulk data is kept: the storage worker, or memory in tests.

final class EntryStoreProvider
    extends $FunctionalProvider<EntryStore, EntryStore, EntryStore>
    with $Provider<EntryStore> {
  /// Where bulk data is kept: the storage worker, or memory in tests.
  EntryStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entryStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entryStoreHash();

  @$internal
  @override
  $ProviderElement<EntryStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EntryStore create(Ref ref) {
    return entryStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntryStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntryStore>(value),
    );
  }
}

String _$entryStoreHash() => r'7f8005362754560db526117951b0e2e61f952fc2';
