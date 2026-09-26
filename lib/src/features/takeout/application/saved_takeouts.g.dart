// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_takeouts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every saved takeout, newest export first, read from each one's small
/// summary files rather than all its data. The loaded takeout's comes from
/// its data.

@ProviderFor(SavedTakeouts)
final savedTakeoutsProvider = SavedTakeoutsProvider._();

/// Every saved takeout, newest export first, read from each one's small
/// summary files rather than all its data. The loaded takeout's comes from
/// its data.
final class SavedTakeoutsProvider
    extends $AsyncNotifierProvider<SavedTakeouts, List<TakeoutSummary>> {
  /// Every saved takeout, newest export first, read from each one's small
  /// summary files rather than all its data. The loaded takeout's comes from
  /// its data.
  SavedTakeoutsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedTakeoutsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedTakeoutsHash();

  @$internal
  @override
  SavedTakeouts create() => SavedTakeouts();
}

String _$savedTakeoutsHash() => r'52706c83d0dcd1bbb7923565131f5e364b3a2b4e';

/// Every saved takeout, newest export first, read from each one's small
/// summary files rather than all its data. The loaded takeout's comes from
/// its data.

abstract class _$SavedTakeouts extends $AsyncNotifier<List<TakeoutSummary>> {
  FutureOr<List<TakeoutSummary>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<TakeoutSummary>>, List<TakeoutSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TakeoutSummary>>,
                List<TakeoutSummary>
              >,
              AsyncValue<List<TakeoutSummary>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
