// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether an export is running. Kept alive so an export outlives the
/// widget that started it.

@ProviderFor(ExportNotifier)
final exportProvider = ExportNotifierProvider._();

/// Whether an export is running. Kept alive so an export outlives the
/// widget that started it.
final class ExportNotifierProvider
    extends $NotifierProvider<ExportNotifier, bool> {
  /// Whether an export is running. Kept alive so an export outlives the
  /// widget that started it.
  ExportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportNotifierHash();

  @$internal
  @override
  ExportNotifier create() => ExportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$exportNotifierHash() => r'4858c9c9729f7b64aae6d3bc1e59233abdbc6451';

/// Whether an export is running. Kept alive so an export outlives the
/// widget that started it.

abstract class _$ExportNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
