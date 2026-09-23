// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`. Loaded from cache on start; [resolveMissing] looks up the rest.

@ProviderFor(EmojiNames)
final emojiNamesProvider = EmojiNamesProvider._();

/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`. Loaded from cache on start; [resolveMissing] looks up the rest.
final class EmojiNamesProvider
    extends $NotifierProvider<EmojiNames, EmojiNamesState> {
  /// Custom emoji names resolved from YouTube live chat replays, keyed by
  /// `emojiKey`. Loaded from cache on start; [resolveMissing] looks up the rest.
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

String _$emojiNamesHash() => r'dad11252f27e3f4767f8135855c3b8940d1ad214';

/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`. Loaded from cache on start; [resolveMissing] looks up the rest.

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

String _$emojiNamesByKeyHash() => r'86afded6d6e94a7874a3fe7fe2c3a5622e983e44';

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
