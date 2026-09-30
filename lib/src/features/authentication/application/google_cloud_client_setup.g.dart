// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_cloud_client_setup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sets up, changes or removes the Google Cloud client users bring when the
/// build has none. Nothing depends on it, so it can use any provider.

@ProviderFor(GoogleCloudClientSetup)
final googleCloudClientSetupProvider = GoogleCloudClientSetupProvider._();

/// Sets up, changes or removes the Google Cloud client users bring when the
/// build has none. Nothing depends on it, so it can use any provider.
final class GoogleCloudClientSetupProvider
    extends $NotifierProvider<GoogleCloudClientSetup, void> {
  /// Sets up, changes or removes the Google Cloud client users bring when the
  /// build has none. Nothing depends on it, so it can use any provider.
  GoogleCloudClientSetupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleCloudClientSetupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleCloudClientSetupHash();

  @$internal
  @override
  GoogleCloudClientSetup create() => GoogleCloudClientSetup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$googleCloudClientSetupHash() =>
    r'd6c06fd0be64050ead3075632bec4774c2720bf6';

/// Sets up, changes or removes the Google Cloud client users bring when the
/// build has none. Nothing depends on it, so it can use any provider.

abstract class _$GoogleCloudClientSetup extends $Notifier<void> {
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
