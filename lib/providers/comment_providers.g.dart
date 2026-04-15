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

String _$allCommentsHash() => r'b31010c52a56d62b49f287a2c037a714d784c6c9';

@ProviderFor(commentsByChannel)
final commentsByChannelProvider = CommentsByChannelProvider._();

final class CommentsByChannelProvider
    extends
        $FunctionalProvider<
          Map<String, List<Comment>>,
          Map<String, List<Comment>>,
          Map<String, List<Comment>>
        >
    with $Provider<Map<String, List<Comment>>> {
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

String _$commentsByChannelHash() => r'29cb2e08ad7cd9091e4369f75d93e118783a0a4f';

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
         isAutoDispose: false,
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

String _$channelCommentsHash() => r'f15e1fc2dc71f7287d873e3410cfebe15ab65f31';

final class ChannelCommentsFamily extends $Family
    with $FunctionalFamilyOverride<List<Comment>, String> {
  ChannelCommentsFamily._()
    : super(
        retry: null,
        name: r'channelCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ChannelCommentsProvider call(String channelId) =>
      ChannelCommentsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'channelCommentsProvider';
}
