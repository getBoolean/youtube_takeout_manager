// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_account_import.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Imports a takeout in place: as its own account, or merged into its saved
/// account only if the user says so. Nothing is ever replaced.

@ProviderFor(AddAccountImport)
final addAccountImportProvider = AddAccountImportProvider._();

/// Imports a takeout in place: as its own account, or merged into its saved
/// account only if the user says so. Nothing is ever replaced.
final class AddAccountImportProvider
    extends $NotifierProvider<AddAccountImport, AddAccountState> {
  /// Imports a takeout in place: as its own account, or merged into its saved
  /// account only if the user says so. Nothing is ever replaced.
  AddAccountImportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addAccountImportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addAccountImportHash();

  @$internal
  @override
  AddAccountImport create() => AddAccountImport();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddAccountState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddAccountState>(value),
    );
  }
}

String _$addAccountImportHash() => r'a6b2a8dc92c99bdf408c86e9e9fb211a8259b652';

/// Imports a takeout in place: as its own account, or merged into its saved
/// account only if the user says so. Nothing is ever replaced.

abstract class _$AddAccountImport extends $Notifier<AddAccountState> {
  AddAccountState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AddAccountState, AddAccountState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddAccountState, AddAccountState>,
              AddAccountState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
