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
    extends $AsyncNotifierProvider<TakeoutNotifier, TakeoutData?> {
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
}

String _$takeoutNotifierHash() => r'd8bea13133b482a16377ad6e9cc6aaf148cabcc2';

abstract class _$TakeoutNotifier extends $AsyncNotifier<TakeoutData?> {
  FutureOr<TakeoutData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TakeoutData?>, TakeoutData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TakeoutData?>, TakeoutData?>,
              AsyncValue<TakeoutData?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
