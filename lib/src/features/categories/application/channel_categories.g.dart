// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_categories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Channels' categories, by channel key, kept on this device. Made by
/// `ChannelCategorizer`.

@ProviderFor(ChannelCategories)
final channelCategoriesProvider = ChannelCategoriesProvider._();

/// Channels' categories, by channel key, kept on this device. Made by
/// `ChannelCategorizer`.
final class ChannelCategoriesProvider
    extends
        $AsyncNotifierProvider<
          ChannelCategories,
          Map<String, ChannelCategory>
        > {
  /// Channels' categories, by channel key, kept on this device. Made by
  /// `ChannelCategorizer`.
  ChannelCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelCategoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelCategoriesHash();

  @$internal
  @override
  ChannelCategories create() => ChannelCategories();
}

String _$channelCategoriesHash() => r'16be3f2f41ceb7262e2f1e0ba29ef3ab22ed216b';

/// Channels' categories, by channel key, kept on this device. Made by
/// `ChannelCategorizer`.

abstract class _$ChannelCategories
    extends $AsyncNotifier<Map<String, ChannelCategory>> {
  FutureOr<Map<String, ChannelCategory>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, ChannelCategory>>,
              Map<String, ChannelCategory>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, ChannelCategory>>,
                Map<String, ChannelCategory>
              >,
              AsyncValue<Map<String, ChannelCategory>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The sub-categories AI made for channels YouTube's don't fit, by category.

@ProviderFor(CustomCategories)
final customCategoriesProvider = CustomCategoriesProvider._();

/// The sub-categories AI made for channels YouTube's don't fit, by category.
final class CustomCategoriesProvider
    extends
        $AsyncNotifierProvider<CustomCategories, Map<String, List<String>>> {
  /// The sub-categories AI made for channels YouTube's don't fit, by category.
  CustomCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customCategoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customCategoriesHash();

  @$internal
  @override
  CustomCategories create() => CustomCategories();
}

String _$customCategoriesHash() => r'1cd26caaf667956503f068bb957cc3495eeca3fd';

/// The sub-categories AI made for channels YouTube's don't fit, by category.

abstract class _$CustomCategories
    extends $AsyncNotifier<Map<String, List<String>>> {
  FutureOr<Map<String, List<String>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, List<String>>>,
              Map<String, List<String>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, List<String>>>,
                Map<String, List<String>>
              >,
              AsyncValue<Map<String, List<String>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Every category: YouTube's, with the sub-categories AI made.

@ProviderFor(categoryTaxonomy)
final categoryTaxonomyProvider = CategoryTaxonomyProvider._();

/// Every category: YouTube's, with the sub-categories AI made.

final class CategoryTaxonomyProvider
    extends $FunctionalProvider<Taxonomy, Taxonomy, Taxonomy>
    with $Provider<Taxonomy> {
  /// Every category: YouTube's, with the sub-categories AI made.
  CategoryTaxonomyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryTaxonomyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryTaxonomyHash();

  @$internal
  @override
  $ProviderElement<Taxonomy> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Taxonomy create(Ref ref) {
    return categoryTaxonomy(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Taxonomy value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Taxonomy>(value),
    );
  }
}

String _$categoryTaxonomyHash() => r'fc9cb56196dbf12ed84d62195e1f498bce99a5c4';
