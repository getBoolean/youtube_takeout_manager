// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_channel_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The channel the history screen's watches are narrowed to, or null for
/// every channel.

@ProviderFor(HistoryChannelFilter)
final historyChannelFilterProvider = HistoryChannelFilterProvider._();

/// The channel the history screen's watches are narrowed to, or null for
/// every channel.
final class HistoryChannelFilterProvider
    extends $NotifierProvider<HistoryChannelFilter, HistoryChannel?> {
  /// The channel the history screen's watches are narrowed to, or null for
  /// every channel.
  HistoryChannelFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyChannelFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyChannelFilterHash();

  @$internal
  @override
  HistoryChannelFilter create() => HistoryChannelFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryChannel? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryChannel?>(value),
    );
  }
}

String _$historyChannelFilterHash() =>
    r'be49639b5a478c41e0454bd1d9270b9026641d18';

/// The channel the history screen's watches are narrowed to, or null for
/// every channel.

abstract class _$HistoryChannelFilter extends $Notifier<HistoryChannel?> {
  HistoryChannel? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HistoryChannel?, HistoryChannel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryChannel?, HistoryChannel?>,
              HistoryChannel?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
