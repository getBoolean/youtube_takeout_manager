// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_deletion_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommentApiDeletion)
final commentApiDeletionProvider = CommentApiDeletionProvider._();

final class CommentApiDeletionProvider
    extends $NotifierProvider<CommentApiDeletion, ApiDeletionResult?> {
  CommentApiDeletionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentApiDeletionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentApiDeletionHash();

  @$internal
  @override
  CommentApiDeletion create() => CommentApiDeletion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiDeletionResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiDeletionResult?>(value),
    );
  }
}

String _$commentApiDeletionHash() =>
    r'3a88b191aa4c73300550270f245b3a7a72ec4b7f';

abstract class _$CommentApiDeletion extends $Notifier<ApiDeletionResult?> {
  ApiDeletionResult? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ApiDeletionResult?, ApiDeletionResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ApiDeletionResult?, ApiDeletionResult?>,
              ApiDeletionResult?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(LiveChatApiDeletion)
final liveChatApiDeletionProvider = LiveChatApiDeletionProvider._();

final class LiveChatApiDeletionProvider
    extends $NotifierProvider<LiveChatApiDeletion, ApiDeletionResult?> {
  LiveChatApiDeletionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveChatApiDeletionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveChatApiDeletionHash();

  @$internal
  @override
  LiveChatApiDeletion create() => LiveChatApiDeletion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiDeletionResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiDeletionResult?>(value),
    );
  }
}

String _$liveChatApiDeletionHash() =>
    r'8c8a25b3cfcf4ff4b5bd6c96da8eceea79bb550c';

abstract class _$LiveChatApiDeletion extends $Notifier<ApiDeletionResult?> {
  ApiDeletionResult? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ApiDeletionResult?, ApiDeletionResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ApiDeletionResult?, ApiDeletionResult?>,
              ApiDeletionResult?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
