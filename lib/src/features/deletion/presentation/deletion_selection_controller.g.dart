// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the set of IDs currently selected for deletion in the UI. Clears
/// when another channel is viewed, whose items these aren't.

@ProviderFor(DeletionSet)
final deletionSetProvider = DeletionSetProvider._();

/// Manages the set of IDs currently selected for deletion in the UI. Clears
/// when another channel is viewed, whose items these aren't.
final class DeletionSetProvider
    extends $NotifierProvider<DeletionSet, Set<String>> {
  /// Manages the set of IDs currently selected for deletion in the UI. Clears
  /// when another channel is viewed, whose items these aren't.
  DeletionSetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletionSetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletionSetHash();

  @$internal
  @override
  DeletionSet create() => DeletionSet();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$deletionSetHash() => r'de6d1c010a7bbb8acc4da165a2732beaf1a90c46';

/// Manages the set of IDs currently selected for deletion in the UI. Clears
/// when another channel is viewed, whose items these aren't.

abstract class _$DeletionSet extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
