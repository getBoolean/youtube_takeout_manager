// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TakeoutNotifier)
final takeoutProvider = TakeoutNotifierProvider._();

final class TakeoutNotifierProvider
    extends $NotifierProvider<TakeoutNotifier, TakeoutData?> {
  TakeoutNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TakeoutData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TakeoutData?>(value),
    );
  }
}

String _$takeoutNotifierHash() => r'94199baf3422537f2e241f5d7241e9da716ff4e5';

abstract class _$TakeoutNotifier extends $Notifier<TakeoutData?> {
  TakeoutData? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TakeoutData?, TakeoutData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TakeoutData?, TakeoutData?>,
              TakeoutData?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
