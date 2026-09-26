// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_deletion_ids.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the set of comment and/or live chat IDs selected for script-based
/// deletion via My Activity. Used to pass data to the ScriptDeletionScreen
/// since large ID sets can't be passed via route parameters. Clears when
/// another channel is viewed, whose items these aren't.

@ProviderFor(ScriptDeletionIds)
final scriptDeletionIdsProvider = ScriptDeletionIdsProvider._();

/// Holds the set of comment and/or live chat IDs selected for script-based
/// deletion via My Activity. Used to pass data to the ScriptDeletionScreen
/// since large ID sets can't be passed via route parameters. Clears when
/// another channel is viewed, whose items these aren't.
final class ScriptDeletionIdsProvider
    extends $NotifierProvider<ScriptDeletionIds, Set<String>> {
  /// Holds the set of comment and/or live chat IDs selected for script-based
  /// deletion via My Activity. Used to pass data to the ScriptDeletionScreen
  /// since large ID sets can't be passed via route parameters. Clears when
  /// another channel is viewed, whose items these aren't.
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

String _$scriptDeletionIdsHash() => r'aff2edfe8d109ee1849855630bf597e6cf0b6e8f';

/// Holds the set of comment and/or live chat IDs selected for script-based
/// deletion via My Activity. Used to pass data to the ScriptDeletionScreen
/// since large ID sets can't be passed via route parameters. Clears when
/// another channel is viewed, whose items these aren't.

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
