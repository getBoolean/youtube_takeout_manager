// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorization_inputs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What categorizing works from, once the history screen has been opened;
/// null before, so history isn't loaded for it at startup.

@ProviderFor(categorizationInputs)
final categorizationInputsProvider = CategorizationInputsProvider._();

/// What categorizing works from, once the history screen has been opened;
/// null before, so history isn't loaded for it at startup.

final class CategorizationInputsProvider
    extends
        $FunctionalProvider<
          CategorizationInputs?,
          CategorizationInputs?,
          CategorizationInputs?
        >
    with $Provider<CategorizationInputs?> {
  /// What categorizing works from, once the history screen has been opened;
  /// null before, so history isn't loaded for it at startup.
  CategorizationInputsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categorizationInputsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categorizationInputsHash();

  @$internal
  @override
  $ProviderElement<CategorizationInputs?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategorizationInputs? create(Ref ref) {
    return categorizationInputs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategorizationInputs? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategorizationInputs?>(value),
    );
  }
}

String _$categorizationInputsHash() =>
    r'6f715fa2fc6ed365964c664a5cdfa097c22370ce';
