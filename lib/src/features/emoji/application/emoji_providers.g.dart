// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`, kept on this device. Looking up the rest is
/// `EmojiNameResolver`'s.

@ProviderFor(EmojiNames)
final emojiNamesProvider = EmojiNamesProvider._();

/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`, kept on this device. Looking up the rest is
/// `EmojiNameResolver`'s.
final class EmojiNamesProvider
    extends $NotifierProvider<EmojiNames, EmojiNamesState> {
  /// Custom emoji names resolved from YouTube live chat replays, keyed by
  /// `emojiKey`, kept on this device. Looking up the rest is
  /// `EmojiNameResolver`'s.
  EmojiNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emojiNamesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emojiNamesHash();

  @$internal
  @override
  EmojiNames create() => EmojiNames();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmojiNamesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmojiNamesState>(value),
    );
  }
}

String _$emojiNamesHash() => r'4fd36edef5ee380004bde61ce576b352accda714';

/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`, kept on this device. Looking up the rest is
/// `EmojiNameResolver`'s.

abstract class _$EmojiNames extends $Notifier<EmojiNamesState> {
  EmojiNamesState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EmojiNamesState, EmojiNamesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EmojiNamesState, EmojiNamesState>,
              EmojiNamesState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Resolved emoji names keyed by `emojiKey`, for search matching.

@ProviderFor(emojiNamesByKey)
final emojiNamesByKeyProvider = EmojiNamesByKeyProvider._();

/// Resolved emoji names keyed by `emojiKey`, for search matching.

final class EmojiNamesByKeyProvider
    extends
        $FunctionalProvider<
          Map<String, String>,
          Map<String, String>,
          Map<String, String>
        >
    with $Provider<Map<String, String>> {
  /// Resolved emoji names keyed by `emojiKey`, for search matching.
  EmojiNamesByKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emojiNamesByKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emojiNamesByKeyHash();

  @$internal
  @override
  $ProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, String> create(Ref ref) {
    return emojiNamesByKey(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$emojiNamesByKeyHash() => r'399c47b22a9a067f9f175338a99305afc46668b5';

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

String _$channelEmojisHash() => r'4750806adeccc5e3e67d4e6ce53ad960847c99c7';

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
    r'd015f9dc7250f39aae55e6b7a78d0ab62a3473df';

/// Emojis the user inserted into a search, most used first (ties: most
/// recent). Once full, the least recently used entry makes room for a new one.

@ProviderFor(FrequentEmojis)
final frequentEmojisProvider = FrequentEmojisProvider._();

/// Emojis the user inserted into a search, most used first (ties: most
/// recent). Once full, the least recently used entry makes room for a new one.
final class FrequentEmojisProvider
    extends $AsyncNotifierProvider<FrequentEmojis, List<EmojiUse>> {
  /// Emojis the user inserted into a search, most used first (ties: most
  /// recent). Once full, the least recently used entry makes room for a new one.
  FrequentEmojisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'frequentEmojisProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$frequentEmojisHash();

  @$internal
  @override
  FrequentEmojis create() => FrequentEmojis();
}

String _$frequentEmojisHash() => r'0af6917bc8d80a4c3618e10e0f367aed837ef2d0';

/// Emojis the user inserted into a search, most used first (ties: most
/// recent). Once full, the least recently used entry makes room for a new one.

abstract class _$FrequentEmojis extends $AsyncNotifier<List<EmojiUse>> {
  FutureOr<List<EmojiUse>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<EmojiUse>>, List<EmojiUse>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<EmojiUse>>, List<EmojiUse>>,
              AsyncValue<List<EmojiUse>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

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
    r'b52f74afe96c21b4a82a8b1d602d53328cc4876a';

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

/// Standard emojis in each channel's comments and live chats: the ones a
/// search there would find (see [UnicodeEmojiCatalog.find]).

@ProviderFor(unicodeEmojisByChannel)
final unicodeEmojisByChannelProvider = UnicodeEmojisByChannelProvider._();

/// Standard emojis in each channel's comments and live chats: the ones a
/// search there would find (see [UnicodeEmojiCatalog.find]).

final class UnicodeEmojisByChannelProvider
    extends
        $FunctionalProvider<
          Map<String, Set<UnicodeEmoji>>,
          Map<String, Set<UnicodeEmoji>>,
          Map<String, Set<UnicodeEmoji>>
        >
    with $Provider<Map<String, Set<UnicodeEmoji>>> {
  /// Standard emojis in each channel's comments and live chats: the ones a
  /// search there would find (see [UnicodeEmojiCatalog.find]).
  UnicodeEmojisByChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unicodeEmojisByChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unicodeEmojisByChannelHash();

  @$internal
  @override
  $ProviderElement<Map<String, Set<UnicodeEmoji>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, Set<UnicodeEmoji>> create(Ref ref) {
    return unicodeEmojisByChannel(ref);
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

String _$unicodeEmojisByChannelHash() =>
    r'045a70835b3f351f365516ce70992fda01bc4576';

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
    r'd3d59c451f3b9dfd57eca9683a36052f4fb73718';

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
    r'06b9c2d96ca2384fb58ab87eb9b0b18f6eefc476';

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
    r'134ebcc73eeee3d81eaef5319b4bfbd32d9247a7';

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
