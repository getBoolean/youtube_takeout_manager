// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_channel_selection.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The channels the history screen's watched videos are narrowed to, and
/// the categories whose channels are; none for every channel.

@ProviderFor(HistoryChannelSelection)
final historyChannelSelectionProvider = HistoryChannelSelectionProvider._();

/// The channels the history screen's watched videos are narrowed to, and
/// the categories whose channels are; none for every channel.
final class HistoryChannelSelectionProvider
    extends $NotifierProvider<HistoryChannelSelection, ChannelSelection> {
  /// The channels the history screen's watched videos are narrowed to, and
  /// the categories whose channels are; none for every channel.
  HistoryChannelSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyChannelSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyChannelSelectionHash();

  @$internal
  @override
  HistoryChannelSelection create() => HistoryChannelSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChannelSelection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChannelSelection>(value),
    );
  }
}

String _$historyChannelSelectionHash() =>
    r'604d9b5721f619b9f75d4da78797bb1d95877f35';

/// The channels the history screen's watched videos are narrowed to, and
/// the categories whose channels are; none for every channel.

abstract class _$HistoryChannelSelection extends $Notifier<ChannelSelection> {
  ChannelSelection build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChannelSelection, ChannelSelection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChannelSelection, ChannelSelection>,
              ChannelSelection,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
