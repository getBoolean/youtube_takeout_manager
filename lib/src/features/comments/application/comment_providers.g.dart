// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(allComments)
final allCommentsProvider = AllCommentsProvider._();

final class AllCommentsProvider
    extends $FunctionalProvider<List<Comment>, List<Comment>, List<Comment>>
    with $Provider<List<Comment>> {
  AllCommentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allCommentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allCommentsHash();

  @$internal
  @override
  $ProviderElement<List<Comment>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Comment> create(Ref ref) {
    return allComments(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Comment> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Comment>>(value),
    );
  }
}

String _$allCommentsHash() => r'cb422f69c5c462a5960a908fef4e7eff3197faa1';

/// Comments by the channel their video is on. Comments whose video's channel
/// isn't known are kept under [unknownChannelId].

@ProviderFor(commentsByChannel)
final commentsByChannelProvider = CommentsByChannelProvider._();

/// Comments by the channel their video is on. Comments whose video's channel
/// isn't known are kept under [unknownChannelId].

final class CommentsByChannelProvider
    extends
        $FunctionalProvider<
          Map<String, List<Comment>>,
          Map<String, List<Comment>>,
          Map<String, List<Comment>>
        >
    with $Provider<Map<String, List<Comment>>> {
  /// Comments by the channel their video is on. Comments whose video's channel
  /// isn't known are kept under [unknownChannelId].
  CommentsByChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commentsByChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commentsByChannelHash();

  @$internal
  @override
  $ProviderElement<Map<String, List<Comment>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, List<Comment>> create(Ref ref) {
    return commentsByChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<Comment>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<Comment>>>(value),
    );
  }
}

String _$commentsByChannelHash() => r'4b5721ff7944d045a6655af7aa04541ca6b86ed0';

@ProviderFor(channelComments)
final channelCommentsProvider = ChannelCommentsFamily._();

final class ChannelCommentsProvider
    extends $FunctionalProvider<List<Comment>, List<Comment>, List<Comment>>
    with $Provider<List<Comment>> {
  ChannelCommentsProvider._({
    required ChannelCommentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'channelCommentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelCommentsHash();

  @override
  String toString() {
    return r'channelCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Comment>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Comment> create(Ref ref) {
    final argument = this.argument as String;
    return channelComments(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Comment> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Comment>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelCommentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelCommentsHash() => r'97996d4532e9a2292cd7e3c256d170f4a37d7f27';

final class ChannelCommentsFamily extends $Family
    with $FunctionalFamilyOverride<List<Comment>, String> {
  ChannelCommentsFamily._()
    : super(
        retry: null,
        name: r'channelCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChannelCommentsProvider call(String channelId) =>
      ChannelCommentsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'channelCommentsProvider';
}
