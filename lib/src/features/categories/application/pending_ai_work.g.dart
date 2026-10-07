// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_ai_work.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What a run with AI would do now, as the categorizer last worked it out:
/// a moment after what it depends on changes, held while a run goes, and
/// once more when it ends. None before the history is shown.

@ProviderFor(PendingAiWork)
final pendingAiWorkProvider = PendingAiWorkProvider._();

/// What a run with AI would do now, as the categorizer last worked it out:
/// a moment after what it depends on changes, held while a run goes, and
/// once more when it ends. None before the history is shown.
final class PendingAiWorkProvider
    extends $NotifierProvider<PendingAiWork, AiWorkSummary?> {
  /// What a run with AI would do now, as the categorizer last worked it out:
  /// a moment after what it depends on changes, held while a run goes, and
  /// once more when it ends. None before the history is shown.
  PendingAiWorkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingAiWorkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingAiWorkHash();

  @$internal
  @override
  PendingAiWork create() => PendingAiWork();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiWorkSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiWorkSummary?>(value),
    );
  }
}

String _$pendingAiWorkHash() => r'675a7fd35e3169fcd86b03c70350e3abbe354adc';

/// What a run with AI would do now, as the categorizer last worked it out:
/// a moment after what it depends on changes, held while a run goes, and
/// once more when it ends. None before the history is shown.

abstract class _$PendingAiWork extends $Notifier<AiWorkSummary?> {
  AiWorkSummary? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AiWorkSummary?, AiWorkSummary?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiWorkSummary?, AiWorkSummary?>,
              AiWorkSummary?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
