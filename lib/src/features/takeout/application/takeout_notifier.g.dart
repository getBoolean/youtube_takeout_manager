// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeout_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The selected saved takeout, with every channel's items. Reloads when
/// another takeout is selected. Importing is `TakeoutImporter`'s.

@ProviderFor(TakeoutNotifier)
final takeoutProvider = TakeoutNotifierProvider._();

/// The selected saved takeout, with every channel's items. Reloads when
/// another takeout is selected. Importing is `TakeoutImporter`'s.
final class TakeoutNotifierProvider
    extends $AsyncNotifierProvider<TakeoutNotifier, LoadedTakeout?> {
  /// The selected saved takeout, with every channel's items. Reloads when
  /// another takeout is selected. Importing is `TakeoutImporter`'s.
  TakeoutNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryLoadBriefly,
        name: r'takeoutProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$takeoutNotifierHash();

  @$internal
  @override
  TakeoutNotifier create() => TakeoutNotifier();
}

String _$takeoutNotifierHash() => r'85b0bd680a072f1202fe96e44cbd8d1ad408f17f';

/// The selected saved takeout, with every channel's items. Reloads when
/// another takeout is selected. Importing is `TakeoutImporter`'s.

abstract class _$TakeoutNotifier extends $AsyncNotifier<LoadedTakeout?> {
  FutureOr<LoadedTakeout?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LoadedTakeout?>, LoadedTakeout?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LoadedTakeout?>, LoadedTakeout?>,
              AsyncValue<LoadedTakeout?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
