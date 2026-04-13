// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_deletion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the set of comment IDs selected for script-based deletion via
/// My Activity. Used to pass data to the ScriptDeletionScreen since large
/// ID sets can't be passed via route parameters.

@ProviderFor(ScriptDeletionIds)
final scriptDeletionIdsProvider = ScriptDeletionIdsProvider._();

/// Holds the set of comment IDs selected for script-based deletion via
/// My Activity. Used to pass data to the ScriptDeletionScreen since large
/// ID sets can't be passed via route parameters.
final class ScriptDeletionIdsProvider
    extends $NotifierProvider<ScriptDeletionIds, Set<String>> {
  /// Holds the set of comment IDs selected for script-based deletion via
  /// My Activity. Used to pass data to the ScriptDeletionScreen since large
  /// ID sets can't be passed via route parameters.
  ScriptDeletionIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scriptDeletionIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scriptDeletionIdsHash();

  @$internal
  @override
  ScriptDeletionIds create() => ScriptDeletionIds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$scriptDeletionIdsHash() => r'434ae901e0a7fba73a4c60c408b442a05370673a';

/// Holds the set of comment IDs selected for script-based deletion via
/// My Activity. Used to pass data to the ScriptDeletionScreen since large
/// ID sets can't be passed via route parameters.

abstract class _$ScriptDeletionIds extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
