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
    extends $AsyncNotifierProvider<TakeoutHistoryNotifier, LoadedHistory?> {
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
    r'57ccb551a76e317fd4c3135240c1f55d1c6cf325';

/// The selected takeout's watch and search history, or null when no
/// takeout is selected. Loaded apart from the takeout, when first looked
/// at; an import that saves new history invalidates it.

abstract class _$TakeoutHistoryNotifier extends $AsyncNotifier<LoadedHistory?> {
  FutureOr<LoadedHistory?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LoadedHistory?>, LoadedHistory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LoadedHistory?>, LoadedHistory?>,
              AsyncValue<LoadedHistory?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
