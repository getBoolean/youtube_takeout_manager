// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji_names.dart';

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
