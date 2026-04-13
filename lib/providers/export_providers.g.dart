// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExportNotifier)
final exportProvider = ExportNotifierProvider._();

final class ExportNotifierProvider
    extends $NotifierProvider<ExportNotifier, bool> {
  ExportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportProvider',
        isAutoDispose: true,
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

String _$exportNotifierHash() => r'eff146966d1aa6cf3ec5a9c7043606752f5477ac';

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
