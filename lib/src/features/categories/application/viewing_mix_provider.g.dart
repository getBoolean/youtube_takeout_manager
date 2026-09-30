// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewing_mix_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What was watched by category, of the kinds of videos shown (Shorts and
/// YouTube Music as filtered), whatever else narrows what's shown: every
/// watched channel, and the ones subscribed to but never watched.

@ProviderFor(viewingMix)
final viewingMixProvider = ViewingMixProvider._();

/// What was watched by category, of the kinds of videos shown (Shorts and
/// YouTube Music as filtered), whatever else narrows what's shown: every
/// watched channel, and the ones subscribed to but never watched.

final class ViewingMixProvider
    extends
        $FunctionalProvider<
          List<CategoryShare>,
          List<CategoryShare>,
          List<CategoryShare>
        >
    with $Provider<List<CategoryShare>> {
  /// What was watched by category, of the kinds of videos shown (Shorts and
  /// YouTube Music as filtered), whatever else narrows what's shown: every
  /// watched channel, and the ones subscribed to but never watched.
  ViewingMixProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewingMixProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewingMixHash();

  @$internal
  @override
  $ProviderElement<List<CategoryShare>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CategoryShare> create(Ref ref) {
    return viewingMix(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CategoryShare> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CategoryShare>>(value),
    );
  }
}

String _$viewingMixHash() => r'11cd26f69b8d5c411e81e9095b836b4c55c5efa8';
