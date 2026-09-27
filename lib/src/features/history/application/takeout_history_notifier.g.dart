// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeout_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The selected takeout's watch and search history, or null when no
/// takeout is selected. Loaded apart from the takeout, when first looked
/// at; an import that saves new history invalidates it.

@ProviderFor(TakeoutHistoryNotifier)
final takeoutHistoryProvider = TakeoutHistoryNotifierProvider._();

/// The selected takeout's watch and search history, or null when no
/// takeout is selected. Loaded apart from the takeout, when first looked
/// at; an import that saves new history invalidates it.
final class TakeoutHistoryNotifierProvider
    extends $AsyncNotifierProvider<TakeoutHistoryNotifier, TakeoutHistory?> {
  /// The selected takeout's watch and search history, or null when no
  /// takeout is selected. Loaded apart from the takeout, when first looked
  /// at; an import that saves new history invalidates it.
  TakeoutHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryLoadBriefly,
        name: r'takeoutHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$takeoutHistoryNotifierHash();

  @$internal
  @override
  TakeoutHistoryNotifier create() => TakeoutHistoryNotifier();
}

String _$takeoutHistoryNotifierHash() =>
    r'e1e068315912b752e431c06a7ae085aadea301af';

/// The selected takeout's watch and search history, or null when no
/// takeout is selected. Loaded apart from the takeout, when first looked
/// at; an import that saves new history invalidates it.

abstract class _$TakeoutHistoryNotifier
    extends $AsyncNotifier<TakeoutHistory?> {
  FutureOr<TakeoutHistory?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TakeoutHistory?>, TakeoutHistory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TakeoutHistory?>, TakeoutHistory?>,
              AsyncValue<TakeoutHistory?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
