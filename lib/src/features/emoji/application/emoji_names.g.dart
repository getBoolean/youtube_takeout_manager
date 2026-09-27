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
    extends $AsyncNotifierProvider<EmojiNames, EmojiNamesState> {
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
}

String _$emojiNamesHash() => r'a2159be4c4f66e1a582148c72707488df762b157';

/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`, kept on this device. Looking up the rest is
/// `EmojiNameResolver`'s.

abstract class _$EmojiNames extends $AsyncNotifier<EmojiNamesState> {
  FutureOr<EmojiNamesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EmojiNamesState>, EmojiNamesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EmojiNamesState>, EmojiNamesState>,
              AsyncValue<EmojiNamesState>,
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

String _$emojiNamesByKeyHash() => r'89ac0fe70379f22eaa8a38e177fe235ef830f23f';
