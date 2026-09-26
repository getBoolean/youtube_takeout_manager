// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeout_remover.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Removes saved takeouts, with the queued deletions and sign-ins only they
/// had. A service: nothing depends on it, so it can read any provider.

@ProviderFor(TakeoutRemover)
final takeoutRemoverProvider = TakeoutRemoverProvider._();

/// Removes saved takeouts, with the queued deletions and sign-ins only they
/// had. A service: nothing depends on it, so it can read any provider.
final class TakeoutRemoverProvider
    extends $NotifierProvider<TakeoutRemover, void> {
  /// Removes saved takeouts, with the queued deletions and sign-ins only they
  /// had. A service: nothing depends on it, so it can read any provider.
  TakeoutRemoverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'takeoutRemoverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$takeoutRemoverHash();

  @$internal
  @override
  TakeoutRemover create() => TakeoutRemover();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$takeoutRemoverHash() => r'cd5c68171ed2e0a87a9ab1833940bb0956a9b5e0';

/// Removes saved takeouts, with the queued deletions and sign-ins only they
/// had. A service: nothing depends on it, so it can read any provider.

abstract class _$TakeoutRemover extends $Notifier<void> {
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
