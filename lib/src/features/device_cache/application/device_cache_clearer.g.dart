// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_cache_clearer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Clears what's loaded from YouTube and kept on this device, so it's
/// fetched again. A service: nothing depends on it, so it can read any
/// provider.

@ProviderFor(DeviceCacheClearer)
final deviceCacheClearerProvider = DeviceCacheClearerProvider._();

/// Clears what's loaded from YouTube and kept on this device, so it's
/// fetched again. A service: nothing depends on it, so it can read any
/// provider.
final class DeviceCacheClearerProvider
    extends $NotifierProvider<DeviceCacheClearer, void> {
  /// Clears what's loaded from YouTube and kept on this device, so it's
  /// fetched again. A service: nothing depends on it, so it can read any
  /// provider.
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
    r'e0649922bb8ef581f8deb849bca6be540e383cb7';

/// Clears what's loaded from YouTube and kept on this device, so it's
/// fetched again. A service: nothing depends on it, so it can read any
/// provider.

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
