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
    r'92083d5672f91e0a093460d2f30b4079901d0228';

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
    r'd1509f5274a5c2bbdc4ed054ceabe2c45740c0e1';

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
