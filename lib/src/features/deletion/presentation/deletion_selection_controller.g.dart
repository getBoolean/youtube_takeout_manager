// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the set of IDs currently selected for deletion in the UI. Clears
/// when another channel is viewed, whose items these aren't.

@ProviderFor(DeletionSet)
final deletionSetProvider = DeletionSetProvider._();

/// Manages the set of IDs currently selected for deletion in the UI. Clears
/// when another channel is viewed, whose items these aren't.
final class DeletionSetProvider
    extends $NotifierProvider<DeletionSet, Set<String>> {
  /// Manages the set of IDs currently selected for deletion in the UI. Clears
  /// when another channel is viewed, whose items these aren't.
  DeletionSetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletionSetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletionSetHash();

  @$internal
  @override
  DeletionSet create() => DeletionSet();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$deletionSetHash() => r'de6d1c010a7bbb8acc4da165a2732beaf1a90c46';

/// Manages the set of IDs currently selected for deletion in the UI. Clears
/// when another channel is viewed, whose items these aren't.

abstract class _$DeletionSet extends $Notifier<Set<String>> {
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

/// Splits the current selection into just the comment IDs present in
/// the given channel's comments.

@ProviderFor(selectedCommentIds)
final selectedCommentIdsProvider = SelectedCommentIdsFamily._();

/// Splits the current selection into just the comment IDs present in
/// the given channel's comments.

final class SelectedCommentIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// Splits the current selection into just the comment IDs present in
  /// the given channel's comments.
  SelectedCommentIdsProvider._({
    required SelectedCommentIdsFamily super.from,
    required List<Comment> super.argument,
  }) : super(
         retry: null,
         name: r'selectedCommentIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectedCommentIdsHash();

  @override
  String toString() {
    return r'selectedCommentIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    final argument = this.argument as List<Comment>;
    return selectedCommentIds(ref, argument);
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
    return other is SelectedCommentIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectedCommentIdsHash() =>
    r'479a4931219b5125c663ea9e1f9fcba69a6c5a91';

/// Splits the current selection into just the comment IDs present in
/// the given channel's comments.

final class SelectedCommentIdsFamily extends $Family
    with $FunctionalFamilyOverride<Set<String>, List<Comment>> {
  SelectedCommentIdsFamily._()
    : super(
        retry: null,
        name: r'selectedCommentIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Splits the current selection into just the comment IDs present in
  /// the given channel's comments.

  SelectedCommentIdsProvider call(List<Comment> channelComments) =>
      SelectedCommentIdsProvider._(argument: channelComments, from: this);

  @override
  String toString() => r'selectedCommentIdsProvider';
}

/// Splits the current selection into just the live chat IDs present in
/// the given channel's live chats.

@ProviderFor(selectedLiveChatIds)
final selectedLiveChatIdsProvider = SelectedLiveChatIdsFamily._();

/// Splits the current selection into just the live chat IDs present in
/// the given channel's live chats.

final class SelectedLiveChatIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// Splits the current selection into just the live chat IDs present in
  /// the given channel's live chats.
  SelectedLiveChatIdsProvider._({
    required SelectedLiveChatIdsFamily super.from,
    required List<LiveChat> super.argument,
  }) : super(
         retry: null,
         name: r'selectedLiveChatIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectedLiveChatIdsHash();

  @override
  String toString() {
    return r'selectedLiveChatIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    final argument = this.argument as List<LiveChat>;
    return selectedLiveChatIds(ref, argument);
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
    return other is SelectedLiveChatIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectedLiveChatIdsHash() =>
    r'b7602bb4ae635a05ec89d1e10356d0a89c9aac8b';

/// Splits the current selection into just the live chat IDs present in
/// the given channel's live chats.

final class SelectedLiveChatIdsFamily extends $Family
    with $FunctionalFamilyOverride<Set<String>, List<LiveChat>> {
  SelectedLiveChatIdsFamily._()
    : super(
        retry: null,
        name: r'selectedLiveChatIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Splits the current selection into just the live chat IDs present in
  /// the given channel's live chats.

  SelectedLiveChatIdsProvider call(List<LiveChat> channelLiveChats) =>
      SelectedLiveChatIdsProvider._(argument: channelLiveChats, from: this);

  @override
  String toString() => r'selectedLiveChatIdsProvider';
}
