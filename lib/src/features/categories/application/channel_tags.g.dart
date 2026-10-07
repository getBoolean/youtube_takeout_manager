// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_tags.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every tag there is, as first spelled, with who made it, by its folded
/// name ([nameKey]), kept on this device.

@ProviderFor(TagNames)
final tagNamesProvider = TagNamesProvider._();

/// Every tag there is, as first spelled, with who made it, by its folded
/// name ([nameKey]), kept on this device.
final class TagNamesProvider
    extends $AsyncNotifierProvider<TagNames, Map<String, TagName>> {
  /// Every tag there is, as first spelled, with who made it, by its folded
  /// name ([nameKey]), kept on this device.
  TagNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagNamesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagNamesHash();

  @$internal
  @override
  TagNames create() => TagNames();
}

String _$tagNamesHash() => r'69f963324d3dcec963b2af17e8dd91d912a671a6';

/// Every tag there is, as first spelled, with who made it, by its folded
/// name ([nameKey]), kept on this device.

abstract class _$TagNames extends $AsyncNotifier<Map<String, TagName>> {
  FutureOr<Map<String, TagName>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, TagName>>, Map<String, TagName>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, TagName>>,
                Map<String, TagName>
              >,
              AsyncValue<Map<String, TagName>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Every tag kept and not deleted, with how many channels have it: the
/// user's first, then the most used, ties by name.

@ProviderFor(tagRegistry)
final tagRegistryProvider = TagRegistryProvider._();

/// Every tag kept and not deleted, with how many channels have it: the
/// user's first, then the most used, ties by name.

final class TagRegistryProvider
    extends $FunctionalProvider<List<KeptTag>, List<KeptTag>, List<KeptTag>>
    with $Provider<List<KeptTag>> {
  /// Every tag kept and not deleted, with how many channels have it: the
  /// user's first, then the most used, ties by name.
  TagRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagRegistryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagRegistryHash();

  @$internal
  @override
  $ProviderElement<List<KeptTag>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<KeptTag> create(Ref ref) {
    return tagRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<KeptTag> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<KeptTag>>(value),
    );
  }
}

String _$tagRegistryHash() => r'6d2452eedc11793aefff698c2ea6f8f8a0e47f24';

/// Every tag channels have, the most used first, ties by name.

@ProviderFor(tagUsage)
final tagUsageProvider = TagUsageProvider._();

/// Every tag channels have, the most used first, ties by name.

final class TagUsageProvider
    extends $FunctionalProvider<List<TagUse>, List<TagUse>, List<TagUse>>
    with $Provider<List<TagUse>> {
  /// Every tag channels have, the most used first, ties by name.
  TagUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagUsageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagUsageHash();

  @$internal
  @override
  $ProviderElement<List<TagUse>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<TagUse> create(Ref ref) {
    return tagUsage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TagUse> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TagUse>>(value),
    );
  }
}

String _$tagUsageHash() => r'32f9d0c4dffecf17618ef49ee32196909c83c913';
