// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_account_import.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Adds another Google account's takeout from the account dialog. Never
/// replaces or merges into an account already saved.

@ProviderFor(AddAccountImport)
final addAccountImportProvider = AddAccountImportProvider._();

/// Adds another Google account's takeout from the account dialog. Never
/// replaces or merges into an account already saved.
final class AddAccountImportProvider
    extends $NotifierProvider<AddAccountImport, AddAccountState> {
  /// Adds another Google account's takeout from the account dialog. Never
  /// replaces or merges into an account already saved.
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

String _$addAccountImportHash() => r'3611615f2a0e8242cdb8f4c8720ef779b1623e5e';

/// Adds another Google account's takeout from the account dialog. Never
/// replaces or merges into an account already saved.

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
