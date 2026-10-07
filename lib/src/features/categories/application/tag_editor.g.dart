// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The tags the user defines: a name, and a meaning that lets AI give it
/// to the channels it fits. Defining a tag or changing its meaning marks it
/// changed, so the next run checks every channel for it.
///
/// A service: nothing depends on it, so it can read any provider.

@ProviderFor(TagEditor)
final tagEditorProvider = TagEditorProvider._();

/// The tags the user defines: a name, and a meaning that lets AI give it
/// to the channels it fits. Defining a tag or changing its meaning marks it
/// changed, so the next run checks every channel for it.
///
/// A service: nothing depends on it, so it can read any provider.
final class TagEditorProvider extends $NotifierProvider<TagEditor, void> {
  /// The tags the user defines: a name, and a meaning that lets AI give it
  /// to the channels it fits. Defining a tag or changing its meaning marks it
  /// changed, so the next run checks every channel for it.
  ///
  /// A service: nothing depends on it, so it can read any provider.
  TagEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagEditorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagEditorHash();

  @$internal
  @override
  TagEditor create() => TagEditor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$tagEditorHash() => r'4606d4ce0f057d02cd37224f56c0a28658ea97df';

/// The tags the user defines: a name, and a meaning that lets AI give it
/// to the channels it fits. Defining a tag or changing its meaning marks it
/// changed, so the next run checks every channel for it.
///
/// A service: nothing depends on it, so it can read any provider.

abstract class _$TagEditor extends $Notifier<void> {
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
