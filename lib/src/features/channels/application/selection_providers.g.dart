// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the screen is picking items to delete. Each channel's screen
/// starts out of it whenever it opens, and drops its picks when it closes.

@ProviderFor(SelectionMode)
final selectionModeProvider = SelectionModeFamily._();

/// Whether the screen is picking items to delete. Each channel's screen
/// starts out of it whenever it opens, and drops its picks when it closes.
final class SelectionModeProvider
    extends $NotifierProvider<SelectionMode, bool> {
  /// Whether the screen is picking items to delete. Each channel's screen
  /// starts out of it whenever it opens, and drops its picks when it closes.
  SelectionModeProvider._({
    required SelectionModeFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'selectionModeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectionModeHash();

  @override
  String toString() {
    return r'selectionModeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SelectionMode create() => SelectionMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectionModeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectionModeHash() => r'bb48407789d6931935b15b639422bf8999c58b3a';

/// Whether the screen is picking items to delete. Each channel's screen
/// starts out of it whenever it opens, and drops its picks when it closes.

final class SelectionModeFamily extends $Family
    with $ClassFamilyOverride<SelectionMode, bool, bool, bool, String?> {
  SelectionModeFamily._()
    : super(
        retry: null,
        name: r'selectionModeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the screen is picking items to delete. Each channel's screen
  /// starts out of it whenever it opens, and drops its picks when it closes.

  SelectionModeProvider call({String? channelId}) =>
      SelectionModeProvider._(argument: channelId, from: this);

  @override
  String toString() => r'selectionModeProvider';
}

/// Whether the screen is picking items to delete. Each channel's screen
/// starts out of it whenever it opens, and drops its picks when it closes.

abstract class _$SelectionMode extends $Notifier<bool> {
  late final _$args = ref.$arg as String?;
  String? get channelId => _$args;

  bool build({String? channelId});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(channelId: _$args));
  }
}

/// The items the screen shows that can be picked: the channel's comments and
/// live chats, or the search results.

@ProviderFor(selectionCandidates)
final selectionCandidatesProvider = SelectionCandidatesFamily._();

/// The items the screen shows that can be picked: the channel's comments and
/// live chats, or the search results.

final class SelectionCandidatesProvider
    extends
        $FunctionalProvider<
          List<Interaction>,
          List<Interaction>,
          List<Interaction>
        >
    with $Provider<List<Interaction>> {
  /// The items the screen shows that can be picked: the channel's comments and
  /// live chats, or the search results.
  SelectionCandidatesProvider._({
    required SelectionCandidatesFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'selectionCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectionCandidatesHash();

  @override
  String toString() {
    return r'selectionCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Interaction>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Interaction> create(Ref ref) {
    final argument = this.argument as String?;
    return selectionCandidates(ref, channelId: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Interaction> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Interaction>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectionCandidatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectionCandidatesHash() =>
    r'452eff914f1179a51050f8cf8ce5eff664a91ebf';

/// The items the screen shows that can be picked: the channel's comments and
/// live chats, or the search results.

final class SelectionCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<List<Interaction>, String?> {
  SelectionCandidatesFamily._()
    : super(
        retry: null,
        name: r'selectionCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The items the screen shows that can be picked: the channel's comments and
  /// live chats, or the search results.

  SelectionCandidatesProvider call({String? channelId}) =>
      SelectionCandidatesProvider._(argument: channelId, from: this);

  @override
  String toString() => r'selectionCandidatesProvider';
}

/// The screen's picked items.

@ProviderFor(selectedTargets)
final selectedTargetsProvider = SelectedTargetsFamily._();

/// The screen's picked items.

final class SelectedTargetsProvider
    extends
        $FunctionalProvider<DeletionTargets, DeletionTargets, DeletionTargets>
    with $Provider<DeletionTargets> {
  /// The screen's picked items.
  SelectedTargetsProvider._({
    required SelectedTargetsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'selectedTargetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectedTargetsHash();

  @override
  String toString() {
    return r'selectedTargetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<DeletionTargets> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeletionTargets create(Ref ref) {
    final argument = this.argument as String?;
    return selectedTargets(ref, channelId: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeletionTargets value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeletionTargets>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectedTargetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectedTargetsHash() => r'2aac179fc81352319226e699c19899c688b47c96';

/// The screen's picked items.

final class SelectedTargetsFamily extends $Family
    with $FunctionalFamilyOverride<DeletionTargets, String?> {
  SelectedTargetsFamily._()
    : super(
        retry: null,
        name: r'selectedTargetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The screen's picked items.

  SelectedTargetsProvider call({String? channelId}) =>
      SelectedTargetsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'selectedTargetsProvider';
}

/// The IDs of the screen's items that can still be picked: not deleted,
/// queued or failed.

@ProviderFor(selectableIds)
final selectableIdsProvider = SelectableIdsFamily._();

/// The IDs of the screen's items that can still be picked: not deleted,
/// queued or failed.

final class SelectableIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// The IDs of the screen's items that can still be picked: not deleted,
  /// queued or failed.
  SelectableIdsProvider._({
    required SelectableIdsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'selectableIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectableIdsHash();

  @override
  String toString() {
    return r'selectableIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    final argument = this.argument as String?;
    return selectableIds(ref, channelId: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectableIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectableIdsHash() => r'965dc4413b57d565c26c01817d6bd53544b002a6';

/// The IDs of the screen's items that can still be picked: not deleted,
/// queued or failed.

final class SelectableIdsFamily extends $Family
    with $FunctionalFamilyOverride<Set<String>, String?> {
  SelectableIdsFamily._()
    : super(
        retry: null,
        name: r'selectableIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The IDs of the screen's items that can still be picked: not deleted,
  /// queued or failed.

  SelectableIdsProvider call({String? channelId}) =>
      SelectableIdsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'selectableIdsProvider';
}
