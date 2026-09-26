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

String _$allLiveChatsHash() => r'7f5d800ea1e1980117d1b53438f8d0e3e6b2beaf';

/// Live chats by the channel their video is on. Live chats whose video's
/// channel isn't known are kept under [unknownChannelId].

@ProviderFor(liveChatsByChannel)
final liveChatsByChannelProvider = LiveChatsByChannelProvider._();

/// Live chats by the channel their video is on. Live chats whose video's
/// channel isn't known are kept under [unknownChannelId].

final class LiveChatsByChannelProvider
    extends
        $FunctionalProvider<
          Map<String, List<LiveChat>>,
          Map<String, List<LiveChat>>,
          Map<String, List<LiveChat>>
        >
    with $Provider<Map<String, List<LiveChat>>> {
  /// Live chats by the channel their video is on. Live chats whose video's
  /// channel isn't known are kept under [unknownChannelId].
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
    r'7bf9e46b7fe1cdaa301e56b50b633d3ae312b340';

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

String _$channelLiveChatsHash() => r'aa6e2accbb1853f53973e34e14dcd4170e60c04e';

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
