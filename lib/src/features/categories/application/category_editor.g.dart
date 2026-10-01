// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the user decides about a channel's category and tags, kept: an AI
/// suggestion used or the category kept, YouTube's category used, one
/// chosen or typed in, and tags added or removed. Nothing the user decides
/// is changed by categorizing later.
///
/// A service: nothing depends on it, so it can read any provider.

@ProviderFor(CategoryEditor)
final categoryEditorProvider = CategoryEditorProvider._();

/// What the user decides about a channel's category and tags, kept: an AI
/// suggestion used or the category kept, YouTube's category used, one
/// chosen or typed in, and tags added or removed. Nothing the user decides
/// is changed by categorizing later.
///
/// A service: nothing depends on it, so it can read any provider.
final class CategoryEditorProvider
    extends $NotifierProvider<CategoryEditor, void> {
  /// What the user decides about a channel's category and tags, kept: an AI
  /// suggestion used or the category kept, YouTube's category used, one
  /// chosen or typed in, and tags added or removed. Nothing the user decides
  /// is changed by categorizing later.
  ///
  /// A service: nothing depends on it, so it can read any provider.
  CategoryEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryEditorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryEditorHash();

  @$internal
  @override
  CategoryEditor create() => CategoryEditor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$categoryEditorHash() => r'8fa56ca696ddda91813e70a396ce92392a98e766';

/// What the user decides about a channel's category and tags, kept: an AI
/// suggestion used or the category kept, YouTube's category used, one
/// chosen or typed in, and tags added or removed. Nothing the user decides
/// is changed by categorizing later.
///
/// A service: nothing depends on it, so it can read any provider.

abstract class _$CategoryEditor extends $Notifier<void> {
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
