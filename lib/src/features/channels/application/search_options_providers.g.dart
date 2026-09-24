// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_options_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchOptions)
final searchOptionsProvider = SearchOptionsProvider._();

final class SearchOptionsProvider
    extends $AsyncNotifierProvider<SearchOptions, SearchOptionsState> {
  SearchOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchOptionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchOptionsHash();

  @$internal
  @override
  SearchOptions create() => SearchOptions();
}

String _$searchOptionsHash() => r'ae91a0375609b7ddfea570b83fbd566d5406e2a2';

abstract class _$SearchOptions extends $AsyncNotifier<SearchOptionsState> {
  FutureOr<SearchOptionsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SearchOptionsState>, SearchOptionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SearchOptionsState>, SearchOptionsState>,
              AsyncValue<SearchOptionsState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
