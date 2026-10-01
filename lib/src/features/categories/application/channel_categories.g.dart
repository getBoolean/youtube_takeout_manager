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

/// The sub-categories made for channels YouTube's don't fit, by category:
/// by AI, or typed by the user.

@ProviderFor(CustomCategories)
final customCategoriesProvider = CustomCategoriesProvider._();

/// The sub-categories made for channels YouTube's don't fit, by category:
/// by AI, or typed by the user.
final class CustomCategoriesProvider
    extends
        $AsyncNotifierProvider<
          CustomCategories,
          Map<String, List<SubCategory>>
        > {
  /// The sub-categories made for channels YouTube's don't fit, by category:
  /// by AI, or typed by the user.
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

String _$customCategoriesHash() => r'ecda0d220916a1f4154f08511169558e8a698105';

/// The sub-categories made for channels YouTube's don't fit, by category:
/// by AI, or typed by the user.

abstract class _$CustomCategories
    extends $AsyncNotifier<Map<String, List<SubCategory>>> {
  FutureOr<Map<String, List<SubCategory>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, List<SubCategory>>>,
              Map<String, List<SubCategory>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, List<SubCategory>>>,
                Map<String, List<SubCategory>>
              >,
              AsyncValue<Map<String, List<SubCategory>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Each category's emoji: its sub-category's, YouTube's or as kept with
/// it, else its category's.

@ProviderFor(categoryEmojiOf)
final categoryEmojiOfProvider = CategoryEmojiOfProvider._();

/// Each category's emoji: its sub-category's, YouTube's or as kept with
/// it, else its category's.

final class CategoryEmojiOfProvider
    extends
        $FunctionalProvider<
          String Function(CategoryPath? path),
          String Function(CategoryPath? path),
          String Function(CategoryPath? path)
        >
    with $Provider<String Function(CategoryPath? path)> {
  /// Each category's emoji: its sub-category's, YouTube's or as kept with
  /// it, else its category's.
  CategoryEmojiOfProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryEmojiOfProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryEmojiOfHash();

  @$internal
  @override
  $ProviderElement<String Function(CategoryPath? path)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  String Function(CategoryPath? path) create(Ref ref) {
    return categoryEmojiOf(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String Function(CategoryPath? path) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String Function(CategoryPath? path)>(
        value,
      ),
    );
  }
}

String _$categoryEmojiOfHash() => r'3371fa85e34c69b601fafa80b72a9c545e00b87b';

/// Every category: YouTube's, with the sub-categories made for channels
/// they don't fit.

@ProviderFor(categoryTaxonomy)
final categoryTaxonomyProvider = CategoryTaxonomyProvider._();

/// Every category: YouTube's, with the sub-categories made for channels
/// they don't fit.

final class CategoryTaxonomyProvider
    extends $FunctionalProvider<Taxonomy, Taxonomy, Taxonomy>
    with $Provider<Taxonomy> {
  /// Every category: YouTube's, with the sub-categories made for channels
  /// they don't fit.
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

String _$categoryTaxonomyHash() => r'e6f64b57f463e1f3abd1be9c7db349545db8e94f';
