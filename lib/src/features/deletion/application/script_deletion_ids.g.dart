// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_deletion_ids.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The comments and live chats picked for script-based deletion via My
/// Activity, each under its kind. Used to pass data to the
/// ScriptDeletionScreen since large ID sets can't be passed via route
/// parameters. Clears when another channel is viewed, whose items these
/// aren't.

@ProviderFor(ScriptDeletionIds)
final scriptDeletionIdsProvider = ScriptDeletionIdsProvider._();

/// The comments and live chats picked for script-based deletion via My
/// Activity, each under its kind. Used to pass data to the
/// ScriptDeletionScreen since large ID sets can't be passed via route
/// parameters. Clears when another channel is viewed, whose items these
/// aren't.
final class ScriptDeletionIdsProvider
    extends $NotifierProvider<ScriptDeletionIds, DeletionTargets> {
  /// The comments and live chats picked for script-based deletion via My
  /// Activity, each under its kind. Used to pass data to the
  /// ScriptDeletionScreen since large ID sets can't be passed via route
  /// parameters. Clears when another channel is viewed, whose items these
  /// aren't.
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
  Override overrideWithValue(DeletionTargets value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeletionTargets>(value),
    );
  }
}

String _$scriptDeletionIdsHash() => r'b6e20d059ed9a2fdb231d4e2620d3c6912d2ba18';

/// The comments and live chats picked for script-based deletion via My
/// Activity, each under its kind. Used to pass data to the
/// ScriptDeletionScreen since large ID sets can't be passed via route
/// parameters. Clears when another channel is viewed, whose items these
/// aren't.

abstract class _$ScriptDeletionIds extends $Notifier<DeletionTargets> {
  DeletionTargets build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DeletionTargets, DeletionTargets>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeletionTargets, DeletionTargets>,
              DeletionTargets,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// How many of the script's live chats may be membership events or
/// already-deleted messages, going by the viewed takeout's text.

@ProviderFor(scriptPossibleMembershipEvents)
final scriptPossibleMembershipEventsProvider =
    ScriptPossibleMembershipEventsProvider._();

/// How many of the script's live chats may be membership events or
/// already-deleted messages, going by the viewed takeout's text.

final class ScriptPossibleMembershipEventsProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// How many of the script's live chats may be membership events or
  /// already-deleted messages, going by the viewed takeout's text.
  ScriptPossibleMembershipEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scriptPossibleMembershipEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scriptPossibleMembershipEventsHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return scriptPossibleMembershipEvents(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$scriptPossibleMembershipEventsHash() =>
    r'b28a1cfb22f9826368b66486487676744a6aa963';
