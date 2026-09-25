// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_queue_layout.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the docked queue pane is expanded rather than collapsed to a
/// strip. Shared by every screen that docks it.

@ProviderFor(DeletionQueuePaneExpanded)
final deletionQueuePaneExpandedProvider = DeletionQueuePaneExpandedProvider._();

/// Whether the docked queue pane is expanded rather than collapsed to a
/// strip. Shared by every screen that docks it.
final class DeletionQueuePaneExpandedProvider
    extends $NotifierProvider<DeletionQueuePaneExpanded, bool> {
  /// Whether the docked queue pane is expanded rather than collapsed to a
  /// strip. Shared by every screen that docks it.
  DeletionQueuePaneExpandedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletionQueuePaneExpandedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletionQueuePaneExpandedHash();

  @$internal
  @override
  DeletionQueuePaneExpanded create() => DeletionQueuePaneExpanded();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$deletionQueuePaneExpandedHash() =>
    r'52ae13fd03bc6080bb6b3ff4d0c422e08705fbd3';

/// Whether the docked queue pane is expanded rather than collapsed to a
/// strip. Shared by every screen that docks it.

abstract class _$DeletionQueuePaneExpanded extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
