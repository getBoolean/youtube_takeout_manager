// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_shown.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the history screen was opened this session. History loads when
/// first looked at; background work on it waits for this rather than
/// loading it at startup.

@ProviderFor(HistoryShown)
final historyShownProvider = HistoryShownProvider._();

/// Whether the history screen was opened this session. History loads when
/// first looked at; background work on it waits for this rather than
/// loading it at startup.
final class HistoryShownProvider extends $NotifierProvider<HistoryShown, bool> {
  /// Whether the history screen was opened this session. History loads when
  /// first looked at; background work on it waits for this rather than
  /// loading it at startup.
  HistoryShownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyShownProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyShownHash();

  @$internal
  @override
  HistoryShown create() => HistoryShown();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$historyShownHash() => r'90b87022e0bc1937f41cd5412be37abca785260f';

/// Whether the history screen was opened this session. History loads when
/// first looked at; background work on it waits for this rather than
/// loading it at startup.

abstract class _$HistoryShown extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
