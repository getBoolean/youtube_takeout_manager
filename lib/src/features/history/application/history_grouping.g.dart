// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_grouping.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How the history screen groups the watched videos now: the last grouping
/// picked, kept across restarts, else by channel.

@ProviderFor(HistoryGroupingNotifier)
final historyGroupingProvider = HistoryGroupingNotifierProvider._();

/// How the history screen groups the watched videos now: the last grouping
/// picked, kept across restarts, else by channel.
final class HistoryGroupingNotifierProvider
    extends $AsyncNotifierProvider<HistoryGroupingNotifier, HistoryGrouping> {
  /// How the history screen groups the watched videos now: the last grouping
  /// picked, kept across restarts, else by channel.
  HistoryGroupingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyGroupingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyGroupingNotifierHash();

  @$internal
  @override
  HistoryGroupingNotifier create() => HistoryGroupingNotifier();
}

String _$historyGroupingNotifierHash() =>
    r'236e7e372670bc6d413ae7b80cbe52eddbff9b8d';

/// How the history screen groups the watched videos now: the last grouping
/// picked, kept across restarts, else by channel.

abstract class _$HistoryGroupingNotifier
    extends $AsyncNotifier<HistoryGrouping> {
  FutureOr<HistoryGrouping> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HistoryGrouping>, HistoryGrouping>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HistoryGrouping>, HistoryGrouping>,
              AsyncValue<HistoryGrouping>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
