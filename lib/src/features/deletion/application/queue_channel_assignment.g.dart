// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_channel_assignment.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fills in the channel of queued deletions saved before it was. A service:
/// nothing depends on it, so it can read any provider.

@ProviderFor(QueueChannelAssigner)
final queueChannelAssignerProvider = QueueChannelAssignerProvider._();

/// Fills in the channel of queued deletions saved before it was. A service:
/// nothing depends on it, so it can read any provider.
final class QueueChannelAssignerProvider
    extends $NotifierProvider<QueueChannelAssigner, void> {
  /// Fills in the channel of queued deletions saved before it was. A service:
  /// nothing depends on it, so it can read any provider.
  QueueChannelAssignerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'queueChannelAssignerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$queueChannelAssignerHash();

  @$internal
  @override
  QueueChannelAssigner create() => QueueChannelAssigner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$queueChannelAssignerHash() =>
    r'44f440fc5a1254604189d3848d43a6707a695f50';

/// Fills in the channel of queued deletions saved before it was. A service:
/// nothing depends on it, so it can read any provider.

abstract class _$QueueChannelAssigner extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fills in the channel of queued deletions saved before it was, each time
/// a takeout loads. An effect, started with the app.

@ProviderFor(queueChannelAssignment)
final queueChannelAssignmentProvider = QueueChannelAssignmentProvider._();

/// Fills in the channel of queued deletions saved before it was, each time
/// a takeout loads. An effect, started with the app.

final class QueueChannelAssignmentProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Fills in the channel of queued deletions saved before it was, each time
  /// a takeout loads. An effect, started with the app.
  QueueChannelAssignmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'queueChannelAssignmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$queueChannelAssignmentHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return queueChannelAssignment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$queueChannelAssignmentHash() =>
    r'425df50338f88abf99b3a4162869a4d261c17643';
