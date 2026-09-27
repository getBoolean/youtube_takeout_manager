// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_ids_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The IDs of each kind's items known to be deleted.

@ProviderFor(DeletedIds)
final deletedIdsProvider = DeletedIdsProvider._();

/// The IDs of each kind's items known to be deleted.
final class DeletedIdsProvider
    extends
        $AsyncNotifierProvider<DeletedIds, Map<QueueItemKind, Set<String>>> {
  /// The IDs of each kind's items known to be deleted.
  DeletedIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletedIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletedIdsHash();

  @$internal
  @override
  DeletedIds create() => DeletedIds();
}

String _$deletedIdsHash() => r'8a8833cb242485ab4b27c00fcb0de2ce142ad564';

/// The IDs of each kind's items known to be deleted.

abstract class _$DeletedIds
    extends $AsyncNotifier<Map<QueueItemKind, Set<String>>> {
  FutureOr<Map<QueueItemKind, Set<String>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<QueueItemKind, Set<String>>>,
              Map<QueueItemKind, Set<String>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<QueueItemKind, Set<String>>>,
                Map<QueueItemKind, Set<String>>
              >,
              AsyncValue<Map<QueueItemKind, Set<String>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(queuedIds)
final queuedIdsProvider = QueuedIdsFamily._();

final class QueuedIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  QueuedIdsProvider._({
    required QueuedIdsFamily super.from,
    required QueueItemKind super.argument,
  }) : super(
         retry: null,
         name: r'queuedIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$queuedIdsHash();

  @override
  String toString() {
    return r'queuedIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    final argument = this.argument as QueueItemKind;
    return queuedIds(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QueuedIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$queuedIdsHash() => r'918353a9122167167d351912c3f0953d881af35f';

final class QueuedIdsFamily extends $Family
    with $FunctionalFamilyOverride<Set<String>, QueueItemKind> {
  QueuedIdsFamily._()
    : super(
        retry: null,
        name: r'queuedIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  QueuedIdsProvider call(QueueItemKind kind) =>
      QueuedIdsProvider._(argument: kind, from: this);

  @override
  String toString() => r'queuedIdsProvider';
}

@ProviderFor(failedIds)
final failedIdsProvider = FailedIdsFamily._();

final class FailedIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  FailedIdsProvider._({
    required FailedIdsFamily super.from,
    required QueueItemKind super.argument,
  }) : super(
         retry: null,
         name: r'failedIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$failedIdsHash();

  @override
  String toString() {
    return r'failedIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    final argument = this.argument as QueueItemKind;
    return failedIds(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FailedIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$failedIdsHash() => r'4c9ac97ccf14a2ea9381f9183b8acfc5d08d0b47';

final class FailedIdsFamily extends $Family
    with $FunctionalFamilyOverride<Set<String>, QueueItemKind> {
  FailedIdsFamily._()
    : super(
        retry: null,
        name: r'failedIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FailedIdsProvider call(QueueItemKind kind) =>
      FailedIdsProvider._(argument: kind, from: this);

  @override
  String toString() => r'failedIdsProvider';
}

/// Which of [kind]'s items are deleted, failed or queued.

@ProviderFor(interactionStatuses)
final interactionStatusesProvider = InteractionStatusesFamily._();

/// Which of [kind]'s items are deleted, failed or queued.

final class InteractionStatusesProvider
    extends
        $FunctionalProvider<
          InteractionStatuses,
          InteractionStatuses,
          InteractionStatuses
        >
    with $Provider<InteractionStatuses> {
  /// Which of [kind]'s items are deleted, failed or queued.
  InteractionStatusesProvider._({
    required InteractionStatusesFamily super.from,
    required QueueItemKind super.argument,
  }) : super(
         retry: null,
         name: r'interactionStatusesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$interactionStatusesHash();

  @override
  String toString() {
    return r'interactionStatusesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<InteractionStatuses> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InteractionStatuses create(Ref ref) {
    final argument = this.argument as QueueItemKind;
    return interactionStatuses(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InteractionStatuses value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InteractionStatuses>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InteractionStatusesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$interactionStatusesHash() =>
    r'377bad4faed35ab8ae377117b28893416531ac18';

/// Which of [kind]'s items are deleted, failed or queued.

final class InteractionStatusesFamily extends $Family
    with $FunctionalFamilyOverride<InteractionStatuses, QueueItemKind> {
  InteractionStatusesFamily._()
    : super(
        retry: null,
        name: r'interactionStatusesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Which of [kind]'s items are deleted, failed or queued.

  InteractionStatusesProvider call(QueueItemKind kind) =>
      InteractionStatusesProvider._(argument: kind, from: this);

  @override
  String toString() => r'interactionStatusesProvider';
}

/// The IDs of each kind's items bulk deletes leave out: already deleted,
/// queued or failed.

@ProviderFor(excludedFromDeletionIds)
final excludedFromDeletionIdsProvider = ExcludedFromDeletionIdsProvider._();

/// The IDs of each kind's items bulk deletes leave out: already deleted,
/// queued or failed.

final class ExcludedFromDeletionIdsProvider
    extends
        $FunctionalProvider<
          Map<QueueItemKind, Set<String>>,
          Map<QueueItemKind, Set<String>>,
          Map<QueueItemKind, Set<String>>
        >
    with $Provider<Map<QueueItemKind, Set<String>>> {
  /// The IDs of each kind's items bulk deletes leave out: already deleted,
  /// queued or failed.
  ExcludedFromDeletionIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'excludedFromDeletionIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$excludedFromDeletionIdsHash();

  @$internal
  @override
  $ProviderElement<Map<QueueItemKind, Set<String>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<QueueItemKind, Set<String>> create(Ref ref) {
    return excludedFromDeletionIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<QueueItemKind, Set<String>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<QueueItemKind, Set<String>>>(
        value,
      ),
    );
  }
}

String _$excludedFromDeletionIdsHash() =>
    r'1ae005e2184e36ab15de46bef4654d819771d5b1';
