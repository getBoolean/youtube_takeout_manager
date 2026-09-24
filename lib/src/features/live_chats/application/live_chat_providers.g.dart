// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(allLiveChats)
final allLiveChatsProvider = AllLiveChatsProvider._();

final class AllLiveChatsProvider
    extends $FunctionalProvider<List<LiveChat>, List<LiveChat>, List<LiveChat>>
    with $Provider<List<LiveChat>> {
  AllLiveChatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allLiveChatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allLiveChatsHash();

  @$internal
  @override
  $ProviderElement<List<LiveChat>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<LiveChat> create(Ref ref) {
    return allLiveChats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LiveChat> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LiveChat>>(value),
    );
  }
}

String _$allLiveChatsHash() => r'20d0553bbbff085eb00e89a0f145bbe2668825ad';

@ProviderFor(liveChatsByChannel)
final liveChatsByChannelProvider = LiveChatsByChannelProvider._();

final class LiveChatsByChannelProvider
    extends
        $FunctionalProvider<
          Map<String, List<LiveChat>>,
          Map<String, List<LiveChat>>,
          Map<String, List<LiveChat>>
        >
    with $Provider<Map<String, List<LiveChat>>> {
  LiveChatsByChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveChatsByChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveChatsByChannelHash();

  @$internal
  @override
  $ProviderElement<Map<String, List<LiveChat>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, List<LiveChat>> create(Ref ref) {
    return liveChatsByChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<LiveChat>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<LiveChat>>>(value),
    );
  }
}

String _$liveChatsByChannelHash() =>
    r'db09a4ff14973df0496a37e981e0e2dbd6d5b7c5';

@ProviderFor(channelLiveChats)
final channelLiveChatsProvider = ChannelLiveChatsFamily._();

final class ChannelLiveChatsProvider
    extends $FunctionalProvider<List<LiveChat>, List<LiveChat>, List<LiveChat>>
    with $Provider<List<LiveChat>> {
  ChannelLiveChatsProvider._({
    required ChannelLiveChatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'channelLiveChatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelLiveChatsHash();

  @override
  String toString() {
    return r'channelLiveChatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<LiveChat>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<LiveChat> create(Ref ref) {
    final argument = this.argument as String;
    return channelLiveChats(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LiveChat> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LiveChat>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelLiveChatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelLiveChatsHash() => r'056b1edef236ffb40b36c1d20bffbe35a3276446';

final class ChannelLiveChatsFamily extends $Family
    with $FunctionalFamilyOverride<List<LiveChat>, String> {
  ChannelLiveChatsFamily._()
    : super(
        retry: null,
        name: r'channelLiveChatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChannelLiveChatsProvider call(String channelId) =>
      ChannelLiveChatsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'channelLiveChatsProvider';
}
