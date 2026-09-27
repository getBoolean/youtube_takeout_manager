// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Each channel's comments and live chats read for emojis, parsing each one
/// once.

@ProviderFor(channelEmojiScans)
final channelEmojiScansProvider = ChannelEmojiScansProvider._();

/// Each channel's comments and live chats read for emojis, parsing each one
/// once.

final class ChannelEmojiScansProvider
    extends
        $FunctionalProvider<
          Map<String, ChannelEmojiScan>,
          Map<String, ChannelEmojiScan>,
          Map<String, ChannelEmojiScan>
        >
    with $Provider<Map<String, ChannelEmojiScan>> {
  /// Each channel's comments and live chats read for emojis, parsing each one
  /// once.
  ChannelEmojiScansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelEmojiScansProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelEmojiScansHash();

  @$internal
  @override
  $ProviderElement<Map<String, ChannelEmojiScan>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, ChannelEmojiScan> create(Ref ref) {
    return channelEmojiScans(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, ChannelEmojiScan> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, ChannelEmojiScan>>(
        value,
      ),
    );
  }
}

String _$channelEmojiScansHash() => r'e98f73fe298e97f744ff88e11695597789418317';

/// Custom emojis used in each channel's comments and live chats, most used
/// first.

@ProviderFor(channelEmojis)
final channelEmojisProvider = ChannelEmojisProvider._();

/// Custom emojis used in each channel's comments and live chats, most used
/// first.

final class ChannelEmojisProvider
    extends
        $FunctionalProvider<
          Map<String, List<ChannelEmoji>>,
          Map<String, List<ChannelEmoji>>,
          Map<String, List<ChannelEmoji>>
        >
    with $Provider<Map<String, List<ChannelEmoji>>> {
  /// Custom emojis used in each channel's comments and live chats, most used
  /// first.
  ChannelEmojisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelEmojisProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelEmojisHash();

  @$internal
  @override
  $ProviderElement<Map<String, List<ChannelEmoji>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, List<ChannelEmoji>> create(Ref ref) {
    return channelEmojis(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<ChannelEmoji>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<ChannelEmoji>>>(
        value,
      ),
    );
  }
}

String _$channelEmojisHash() => r'7985027b934eabc6b085a7e7871d4747e7e6a614';

/// Emoji picker sections for every channel with custom emojis, in the same
/// order as the channel list.

@ProviderFor(allChannelEmojiGroups)
final allChannelEmojiGroupsProvider = AllChannelEmojiGroupsProvider._();

/// Emoji picker sections for every channel with custom emojis, in the same
/// order as the channel list.

final class AllChannelEmojiGroupsProvider
    extends
        $FunctionalProvider<
          List<ChannelEmojiGroup>,
          List<ChannelEmojiGroup>,
          List<ChannelEmojiGroup>
        >
    with $Provider<List<ChannelEmojiGroup>> {
  /// Emoji picker sections for every channel with custom emojis, in the same
  /// order as the channel list.
  AllChannelEmojiGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allChannelEmojiGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allChannelEmojiGroupsHash();

  @$internal
  @override
  $ProviderElement<List<ChannelEmojiGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ChannelEmojiGroup> create(Ref ref) {
    return allChannelEmojiGroups(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChannelEmojiGroup> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChannelEmojiGroup>>(value),
    );
  }
}

String _$allChannelEmojiGroupsHash() =>
    r'4e1507a9e53ea02b199909d2c6217d9cf8cf0094';

/// Emoji picker section for a single channel (empty if it has no emojis).

@ProviderFor(channelEmojiGroups)
final channelEmojiGroupsProvider = ChannelEmojiGroupsFamily._();

/// Emoji picker section for a single channel (empty if it has no emojis).

final class ChannelEmojiGroupsProvider
    extends
        $FunctionalProvider<
          List<ChannelEmojiGroup>,
          List<ChannelEmojiGroup>,
          List<ChannelEmojiGroup>
        >
    with $Provider<List<ChannelEmojiGroup>> {
  /// Emoji picker section for a single channel (empty if it has no emojis).
  ChannelEmojiGroupsProvider._({
    required ChannelEmojiGroupsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'channelEmojiGroupsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelEmojiGroupsHash();

  @override
  String toString() {
    return r'channelEmojiGroupsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<ChannelEmojiGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ChannelEmojiGroup> create(Ref ref) {
    final argument = this.argument as String;
    return channelEmojiGroups(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChannelEmojiGroup> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChannelEmojiGroup>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelEmojiGroupsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelEmojiGroupsHash() =>
    r'fc36da58e581522d22757b200ed2bd77ef8efe86';

/// Emoji picker section for a single channel (empty if it has no emojis).

final class ChannelEmojiGroupsFamily extends $Family
    with $FunctionalFamilyOverride<List<ChannelEmojiGroup>, String> {
  ChannelEmojiGroupsFamily._()
    : super(
        retry: null,
        name: r'channelEmojiGroupsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Emoji picker section for a single channel (empty if it has no emojis).

  ChannelEmojiGroupsProvider call(String channelId) =>
      ChannelEmojiGroupsProvider._(argument: channelId, from: this);

  @override
  String toString() => r'channelEmojiGroupsProvider';
}

/// Standard emojis in the titles of each channel's videos that have the
/// user's comments or live chats, which a channel search can match.

@ProviderFor(titleUnicodeEmojisByChannel)
final titleUnicodeEmojisByChannelProvider =
    TitleUnicodeEmojisByChannelProvider._();

/// Standard emojis in the titles of each channel's videos that have the
/// user's comments or live chats, which a channel search can match.

final class TitleUnicodeEmojisByChannelProvider
    extends
        $FunctionalProvider<
          Map<String, Set<UnicodeEmoji>>,
          Map<String, Set<UnicodeEmoji>>,
          Map<String, Set<UnicodeEmoji>>
        >
    with $Provider<Map<String, Set<UnicodeEmoji>>> {
  /// Standard emojis in the titles of each channel's videos that have the
  /// user's comments or live chats, which a channel search can match.
  TitleUnicodeEmojisByChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'titleUnicodeEmojisByChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$titleUnicodeEmojisByChannelHash();

  @$internal
  @override
  $ProviderElement<Map<String, Set<UnicodeEmoji>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, Set<UnicodeEmoji>> create(Ref ref) {
    return titleUnicodeEmojisByChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Set<UnicodeEmoji>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Set<UnicodeEmoji>>>(
        value,
      ),
    );
  }
}

String _$titleUnicodeEmojisByChannelHash() =>
    r'20ee26c9b69b65a73d399a656287189d0758ff09';

/// Standard emojis used in any comment or live chat, in picker order.

@ProviderFor(allUsedUnicodeEmojis)
final allUsedUnicodeEmojisProvider = AllUsedUnicodeEmojisProvider._();

/// Standard emojis used in any comment or live chat, in picker order.

final class AllUsedUnicodeEmojisProvider
    extends
        $FunctionalProvider<
          List<UnicodeEmoji>,
          List<UnicodeEmoji>,
          List<UnicodeEmoji>
        >
    with $Provider<List<UnicodeEmoji>> {
  /// Standard emojis used in any comment or live chat, in picker order.
  AllUsedUnicodeEmojisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allUsedUnicodeEmojisProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allUsedUnicodeEmojisHash();

  @$internal
  @override
  $ProviderElement<List<UnicodeEmoji>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<UnicodeEmoji> create(Ref ref) {
    return allUsedUnicodeEmojis(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<UnicodeEmoji> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<UnicodeEmoji>>(value),
    );
  }
}

String _$allUsedUnicodeEmojisHash() =>
    r'e33ae782da510fe013efb055727a3eaf497fec51';

/// Standard emojis a search of [channelId] can find, in picker order: those
/// in its comments and live chats, and in its video titles while the search
/// matches them.

@ProviderFor(channelUnicodeEmojis)
final channelUnicodeEmojisProvider = ChannelUnicodeEmojisFamily._();

/// Standard emojis a search of [channelId] can find, in picker order: those
/// in its comments and live chats, and in its video titles while the search
/// matches them.

final class ChannelUnicodeEmojisProvider
    extends
        $FunctionalProvider<
          List<UnicodeEmoji>,
          List<UnicodeEmoji>,
          List<UnicodeEmoji>
        >
    with $Provider<List<UnicodeEmoji>> {
  /// Standard emojis a search of [channelId] can find, in picker order: those
  /// in its comments and live chats, and in its video titles while the search
  /// matches them.
  ChannelUnicodeEmojisProvider._({
    required ChannelUnicodeEmojisFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'channelUnicodeEmojisProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelUnicodeEmojisHash();

  @override
  String toString() {
    return r'channelUnicodeEmojisProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<UnicodeEmoji>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<UnicodeEmoji> create(Ref ref) {
    final argument = this.argument as String;
    return channelUnicodeEmojis(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<UnicodeEmoji> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<UnicodeEmoji>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelUnicodeEmojisProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelUnicodeEmojisHash() =>
    r'a6a02460ebb30e6bc7ac9adccaa552b63f9e901f';

/// Standard emojis a search of [channelId] can find, in picker order: those
/// in its comments and live chats, and in its video titles while the search
/// matches them.

final class ChannelUnicodeEmojisFamily extends $Family
    with $FunctionalFamilyOverride<List<UnicodeEmoji>, String> {
  ChannelUnicodeEmojisFamily._()
    : super(
        retry: null,
        name: r'channelUnicodeEmojisProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Standard emojis a search of [channelId] can find, in picker order: those
  /// in its comments and live chats, and in its video titles while the search
  /// matches them.

  ChannelUnicodeEmojisProvider call(String channelId) =>
      ChannelUnicodeEmojisProvider._(argument: channelId, from: this);

  @override
  String toString() => r'channelUnicodeEmojisProvider';
}
