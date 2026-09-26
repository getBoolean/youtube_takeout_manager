// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeout_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The selected saved takeout, with every channel's items. Reloads when
/// another takeout is selected.

@ProviderFor(TakeoutNotifier)
final takeoutProvider = TakeoutNotifierProvider._();

/// The selected saved takeout, with every channel's items. Reloads when
/// another takeout is selected.
final class TakeoutNotifierProvider
    extends $AsyncNotifierProvider<TakeoutNotifier, LoadedTakeout?> {
  /// The selected saved takeout, with every channel's items. Reloads when
  /// another takeout is selected.
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

String _$takeoutNotifierHash() => r'7ed8df9d72b8052bbf89612998958603f4e189c0';

/// The selected saved takeout, with every channel's items. Reloads when
/// another takeout is selected.

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
