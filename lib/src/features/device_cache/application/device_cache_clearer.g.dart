// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_cache_clearer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Clears the pictures and thumbnails kept on this device. A service:
/// nothing depends on it, so it can read any provider.

@ProviderFor(DeviceCacheClearer)
final deviceCacheClearerProvider = DeviceCacheClearerProvider._();

/// Clears the pictures and thumbnails kept on this device. A service:
/// nothing depends on it, so it can read any provider.
final class DeviceCacheClearerProvider
    extends $NotifierProvider<DeviceCacheClearer, void> {
  /// Clears the pictures and thumbnails kept on this device. A service:
  /// nothing depends on it, so it can read any provider.
  DeviceCacheClearerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceCacheClearerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceCacheClearerHash();

  @$internal
  @override
  DeviceCacheClearer create() => DeviceCacheClearer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$deviceCacheClearerHash() =>
    r'b1fd24a0231af4a553c6a2521c767fd9c346faa6';

/// Clears the pictures and thumbnails kept on this device. A service:
/// nothing depends on it, so it can read any provider.

abstract class _$DeviceCacheClearer extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
