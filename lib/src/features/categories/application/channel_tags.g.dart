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

String _$tagNamesHash() => r'8f4b1118bdfc40a933767237a7e4a2dfa887b245';

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
