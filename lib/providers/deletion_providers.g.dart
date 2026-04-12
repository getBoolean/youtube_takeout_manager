// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DeletionSet)
final deletionSetProvider = DeletionSetProvider._();

final class DeletionSetProvider
    extends $NotifierProvider<DeletionSet, Set<String>> {
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

String _$deletionSetHash() => r'6c0446cff0feb69312ec8852ff918450ddd866c6';

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
