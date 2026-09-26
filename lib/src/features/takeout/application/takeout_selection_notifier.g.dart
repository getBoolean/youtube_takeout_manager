// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeout_selection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The saved takeout being shown and the channel chosen in it. Each change
/// shows at once and is saved in the order made, so what's saved always
/// matches the last change.
// A failure is deterministic (legacy data no channel wrote), and retrying
// would parse that data again each time.

@ProviderFor(TakeoutSelectionNotifier)
final takeoutSelectionProvider = TakeoutSelectionNotifierProvider._();

/// The saved takeout being shown and the channel chosen in it. Each change
/// shows at once and is saved in the order made, so what's saved always
/// matches the last change.
// A failure is deterministic (legacy data no channel wrote), and retrying
// would parse that data again each time.
final class TakeoutSelectionNotifierProvider
    extends
        $AsyncNotifierProvider<TakeoutSelectionNotifier, TakeoutSelection?> {
  /// The saved takeout being shown and the channel chosen in it. Each change
  /// shows at once and is saved in the order made, so what's saved always
  /// matches the last change.
  // A failure is deterministic (legacy data no channel wrote), and retrying
  // would parse that data again each time.
  TakeoutSelectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'takeoutSelectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$takeoutSelectionNotifierHash();

  @$internal
  @override
  TakeoutSelectionNotifier create() => TakeoutSelectionNotifier();
}

String _$takeoutSelectionNotifierHash() =>
    r'7b73db6d26b62d658b08051dfff5f69cc86cb125';

/// The saved takeout being shown and the channel chosen in it. Each change
/// shows at once and is saved in the order made, so what's saved always
/// matches the last change.
// A failure is deterministic (legacy data no channel wrote), and retrying
// would parse that data again each time.

abstract class _$TakeoutSelectionNotifier
    extends $AsyncNotifier<TakeoutSelection?> {
  FutureOr<TakeoutSelection?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TakeoutSelection?>, TakeoutSelection?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TakeoutSelection?>, TakeoutSelection?>,
              AsyncValue<TakeoutSelection?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
