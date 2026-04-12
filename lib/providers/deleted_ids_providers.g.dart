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

String _$deletedCommentIdsHash() => r'084e46f459c0121135c824afb8cb062dcd249b99';

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
    r'38cfc85f93bd0fc8ddbdbc705a1938942048b10e';

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
