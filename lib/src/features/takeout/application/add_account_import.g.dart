// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_account_import.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Imports another Google account's takeout from the account dialog. One
/// from an account already saved is merged into it only if the user says
/// so; nothing is ever replaced.

@ProviderFor(AddAccountImport)
final addAccountImportProvider = AddAccountImportProvider._();

/// Imports another Google account's takeout from the account dialog. One
/// from an account already saved is merged into it only if the user says
/// so; nothing is ever replaced.
final class AddAccountImportProvider
    extends $NotifierProvider<AddAccountImport, AddAccountState> {
  /// Imports another Google account's takeout from the account dialog. One
  /// from an account already saved is merged into it only if the user says
  /// so; nothing is ever replaced.
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

String _$addAccountImportHash() => r'31d4358378b9e5ff49259b22283c1fc35338f378';

/// Imports another Google account's takeout from the account dialog. One
/// from an account already saved is merged into it only if the user says
/// so; nothing is ever replaced.

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
