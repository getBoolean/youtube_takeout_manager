// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorization_progress.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How far along categorizing channels is.

@ProviderFor(CategorizationProgress)
final categorizationProgressProvider = CategorizationProgressProvider._();

/// How far along categorizing channels is.
final class CategorizationProgressProvider
    extends $NotifierProvider<CategorizationProgress, RunProgress> {
  /// How far along categorizing channels is.
  CategorizationProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categorizationProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categorizationProgressHash();

  @$internal
  @override
  CategorizationProgress create() => CategorizationProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunProgress>(value),
    );
  }
}

String _$categorizationProgressHash() =>
    r'fd45857200cbc334f9e5114aa4ed760d09f54b64';

/// How far along categorizing channels is.

abstract class _$CategorizationProgress extends $Notifier<RunProgress> {
  RunProgress build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RunProgress, RunProgress>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RunProgress, RunProgress>,
              RunProgress,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The tokens Claude's answers used in the user's run, the one under way or
/// the last: what it cost.

@ProviderFor(ClaudeUsage)
final claudeUsageProvider = ClaudeUsageProvider._();

/// The tokens Claude's answers used in the user's run, the one under way or
/// the last: what it cost.
final class ClaudeUsageProvider
    extends $NotifierProvider<ClaudeUsage, ({int input, int output})> {
  /// The tokens Claude's answers used in the user's run, the one under way or
  /// the last: what it cost.
  ClaudeUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claudeUsageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claudeUsageHash();

  @$internal
  @override
  ClaudeUsage create() => ClaudeUsage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int input, int output}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int input, int output})>(value),
    );
  }
}

String _$claudeUsageHash() => r'a87659f445ffadb3d69226f1ddfa4b0c1a2a39ef';

/// The tokens Claude's answers used in the user's run, the one under way or
/// the last: what it cost.

abstract class _$ClaudeUsage extends $Notifier<({int input, int output})> {
  ({int input, int output}) build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<({int input, int output}), ({int input, int output})>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<({int input, int output}), ({int input, int output})>,
              ({int input, int output}),
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
