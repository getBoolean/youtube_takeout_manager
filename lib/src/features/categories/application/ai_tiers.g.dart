// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_tiers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which AI services categorizing uses this session, and what to say about
/// it. A service is turned back on when its key changes.

@ProviderFor(AiTierStatus)
final aiTierStatusProvider = AiTierStatusProvider._();

/// Which AI services categorizing uses this session, and what to say about
/// it. A service is turned back on when its key changes.
final class AiTierStatusProvider
    extends $NotifierProvider<AiTierStatus, AiTierState> {
  /// Which AI services categorizing uses this session, and what to say about
  /// it. A service is turned back on when its key changes.
  AiTierStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiTierStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiTierStatusHash();

  @$internal
  @override
  AiTierStatus create() => AiTierStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiTierState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiTierState>(value),
    );
  }
}

String _$aiTierStatusHash() => r'9e5baf894c759ff66a9a955c9fb7d00e53a96cca';

/// Which AI services categorizing uses this session, and what to say about
/// it. A service is turned back on when its key changes.

abstract class _$AiTierStatus extends $Notifier<AiTierState> {
  AiTierState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AiTierState, AiTierState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiTierState, AiTierState>,
              AiTierState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
