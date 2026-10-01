// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_results_clearer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Clears what AI made for channels, keeping what the user decided, as
/// [clearAiResults] says: the run under way is stopped first, so nothing it
/// answers is kept, and the next time History opens, channels are
/// categorized again.
///
/// A service: nothing depends on it, so it can read any provider.

@ProviderFor(AiResultsClearer)
final aiResultsClearerProvider = AiResultsClearerProvider._();

/// Clears what AI made for channels, keeping what the user decided, as
/// [clearAiResults] says: the run under way is stopped first, so nothing it
/// answers is kept, and the next time History opens, channels are
/// categorized again.
///
/// A service: nothing depends on it, so it can read any provider.
final class AiResultsClearerProvider
    extends $NotifierProvider<AiResultsClearer, void> {
  /// Clears what AI made for channels, keeping what the user decided, as
  /// [clearAiResults] says: the run under way is stopped first, so nothing it
  /// answers is kept, and the next time History opens, channels are
  /// categorized again.
  ///
  /// A service: nothing depends on it, so it can read any provider.
  AiResultsClearerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiResultsClearerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiResultsClearerHash();

  @$internal
  @override
  AiResultsClearer create() => AiResultsClearer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$aiResultsClearerHash() => r'f30768caf69dfb47a7c67dae6a511810c2598470';

/// Clears what AI made for channels, keeping what the user decided, as
/// [clearAiResults] says: the run under way is stopped first, so nothing it
/// answers is kept, and the next time History opens, channels are
/// categorized again.
///
/// A service: nothing depends on it, so it can read any provider.

abstract class _$AiResultsClearer extends $Notifier<void> {
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
