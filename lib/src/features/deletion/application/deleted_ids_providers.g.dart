// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_ids_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DeletedCommentIds)
final deletedCommentIdsProvider = DeletedCommentIdsProvider._();

final class DeletedCommentIdsProvider
    extends $AsyncNotifierProvider<DeletedCommentIds, Set<String>> {
  DeletedCommentIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletedCommentIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletedCommentIdsHash();

  @$internal
  @override
  DeletedCommentIds create() => DeletedCommentIds();
}

String _$deletedCommentIdsHash() => r'735e6afe1583388779efa0c10e7d1fbe549a3fc8';

abstract class _$DeletedCommentIds extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(DeletedLiveChatIds)
final deletedLiveChatIdsProvider = DeletedLiveChatIdsProvider._();

final class DeletedLiveChatIdsProvider
    extends $AsyncNotifierProvider<DeletedLiveChatIds, Set<String>> {
  DeletedLiveChatIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletedLiveChatIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletedLiveChatIdsHash();

  @$internal
  @override
  DeletedLiveChatIds create() => DeletedLiveChatIds();
}

String _$deletedLiveChatIdsHash() =>
    r'b20c323d73d602c12790fe0ad87917de07de80a6';

abstract class _$DeletedLiveChatIds extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(queuedCommentIds)
final queuedCommentIdsProvider = QueuedCommentIdsProvider._();

final class QueuedCommentIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  QueuedCommentIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'queuedCommentIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$queuedCommentIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return queuedCommentIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$queuedCommentIdsHash() => r'946ec0644ecc1665a63837c9618dbc7dc11b8368';

@ProviderFor(queuedLiveChatIds)
final queuedLiveChatIdsProvider = QueuedLiveChatIdsProvider._();

final class QueuedLiveChatIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  QueuedLiveChatIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'queuedLiveChatIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$queuedLiveChatIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return queuedLiveChatIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$queuedLiveChatIdsHash() => r'4a59a61d713eff6c8cf927db1ff98a8172701a3a';

@ProviderFor(failedCommentIds)
final failedCommentIdsProvider = FailedCommentIdsProvider._();

final class FailedCommentIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  FailedCommentIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'failedCommentIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$failedCommentIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return failedCommentIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$failedCommentIdsHash() => r'99e5515c48c676c8ee15f001e91c9c32d527cf69';

@ProviderFor(failedLiveChatIds)
final failedLiveChatIdsProvider = FailedLiveChatIdsProvider._();

final class FailedLiveChatIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  FailedLiveChatIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'failedLiveChatIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$failedLiveChatIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return failedLiveChatIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$failedLiveChatIdsHash() => r'45827fcbfae5f0f1b56c74edcad3005cc833f521';
