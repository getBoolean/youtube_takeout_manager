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

String _$takeoutImporterHash() => r'ff3060715302a3c528f05728728f38b40952ed48';

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
