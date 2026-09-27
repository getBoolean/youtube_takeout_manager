// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Queues items for deletion, removes them locally, and starts deleting
/// them. A service: nothing depends on it, so it can read any provider.

@ProviderFor(DeletionService)
final deletionServiceProvider = DeletionServiceProvider._();

/// Queues items for deletion, removes them locally, and starts deleting
/// them. A service: nothing depends on it, so it can read any provider.
final class DeletionServiceProvider
    extends $NotifierProvider<DeletionService, void> {
  /// Queues items for deletion, removes them locally, and starts deleting
  /// them. A service: nothing depends on it, so it can read any provider.
  DeletionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletionServiceHash();

  @$internal
  @override
  DeletionService create() => DeletionService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$deletionServiceHash() => r'6ce042b55f3a164e8ad5bfd6f939e8076f4fa32b';

/// Queues items for deletion, removes them locally, and starts deleting
/// them. A service: nothing depends on it, so it can read any provider.

abstract class _$DeletionService extends $Notifier<void> {
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
